// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FT.sol";
import "./Math.sol";
import "./SafeMath.sol";

// @dev 简单设计实现uniswap合约 功能:增加/移出流动性、交易功能、实现手续费功能，千分之三手续费、实现滑点功能
// @note 本合约添加/移除流动性不收取手续费,只有交易收取千分之三手续费
//       同时LPToken只使用数字表示,没有另外创建一个单独的FT合约
//       币对合约则为两个FT合约
//       由于solidity不支持浮点数运算,故部分运行为了避免精度缺失,采用直接乘1000来减少影响
// @author Weihaoming
contract Pair {
    
    event inited(uint256 proportion);
    event LiquidityAdded(address indexed opeartor, uint256 indexed liquidity);
    event LiquidityRemoved(address indexed opeartor, uint256 indexed liquidity);
    event getToken(
        address indexed opeartor, 
        uint256 indexed putTokenAmount, 
        uint256 indexed getTokenAmount, 
        uint256 slipPrice, 
        uint256 fee
    );
    event pledgeToken(
        address indexed opeartor, 
        uint256 indexed pledgeTokenAmount, 
        uint256 indexed getTokenAmount
    );
    event fetchToken(
        address indexed opeartor, 
        uint256 indexed fetchTokenAmount, 
        uint256 indexed getTokenAmount
    );

    // 手续费收取地址,默认为Remix提供的最后一个账户地址
    address public constant FEE_TO_ADDRESS =  0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    // 合约拥有者
    address public owner;
    // token1合约地址
    FT public token1;
    // token2合约地址
    FT public token2;
    // 流动性
    uint256 public liquidity;
    // 总流动性 (x * y = k)
    uint256 public totalLiquidity;
    // token1总量
    uint256 public token1Supply;
    // 比例
    uint256 public proportion;
    // 用户地址 => liquidity
    mapping(address => uint256) public LPTokens;
    // 用户地址 => 质押的token1数量
    mapping(address => uint256) public pledgeToken1List;
    // 用户地址 => 质押的token2数量
    mapping(address => uint256) public pledgeToken2List;
    // 是否已初始化
    int public flag = 0;

    constructor(FT _token1, FT _token2) {
        owner = msg.sender;
        token1 = _token1;
        token2 = _token2;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not the contract's owner");
        _;
    }

    // 判断是不是是否已调用init
    modifier hasInited() {
        require(flag == 1, "don't call the function init firstly");
        _;
    }

    // 第一次添加流动性,确定后续的流动性相关属性
    // 因为第一次添加,无法确定具体流动性属性,故没有计算liquidity、totalLiquidity等
    // 默认token1的数量比token2多
    function init(uint256 token1Amount, uint256 token2Amount) external payable onlyOwner() {
        require(flag == 0);
        // 更新flag
        flag = 1;
        token1Supply = token1Amount;
        // 计算总流动性
        totalLiquidity = token1Amount * token2Amount;
        // 比例
        proportion = token1Amount / token2Amount;
        // 转账
        token1.transferFrom(msg.sender, address(this), token1Amount);
        token2.transferFrom(msg.sender, address(this), token2Amount);
        emit inited(proportion);
    }

    // 增加移动性
    function addLiquidity(uint256 token1Amount, uint256 token2Amount) 
        external 
        payable 
        hasInited() 
        returns (uint256)
    {
        require(token1Amount > 0 && token2Amount > 0);
        // 投入的代币比例与合约中的比例不同,重新进行分配
        if(token1Amount / token2Amount != proportion){
            uint256 total = (token1Amount * proportion + token2Amount) / 2;
            token1Amount = total / proportion;
            token2Amount = total;
        }
        // 增加后的token1 * 增加后的token2
        totalLiquidity = (token1Supply + token1Amount) * (totalLiquidity / token1Supply + token2Amount);
        token1Supply = token1Supply + token1Amount;
        // 流动性为新增代币的总价值在totalSupply的占比
        liquidity = totalLiquidity / (token1Amount * token2Amount) * 100;
        LPTokens[msg.sender] = LPTokens[msg.sender] + liquidity;
        // 转账
        token1.transferFrom(msg.sender, address(this), token1Amount);
        token2.transferFrom(msg.sender, address(this), token2Amount);
        emit LiquidityAdded(msg.sender, liquidity);
        return liquidity;
    }

    // 移除流动性
    function removeLiquidity(uint256 _liquidity) 
        external 
        payable 
        hasInited() 
        returns (uint256, uint256)
    {
        require(_liquidity > 0 && _liquidity <= LPTokens[msg.sender]);
        LPTokens[msg.sender] = LPTokens[msg.sender] - _liquidity;
        // 流动性总价值
        uint256 total = totalLiquidity * 100 / _liquidity;
        // x * y = total
        // x = 10y
        // 10y^2 = total
        uint256 token1Amount = Math.sqrt(total / 10) * proportion;
        uint256 token2Amount = Math.sqrt(total / 10);
        // 减少后的token1 * 减少后的token2
        totalLiquidity = (token1Supply - token1Amount) * (totalLiquidity / token1Supply - token2Amount);
        token1Supply = token1Supply - token1Amount;
        // 转账
        token1.transfer(msg.sender, token1Amount);
        token2.transfer(msg.sender, token2Amount);
        emit LiquidityRemoved(msg.sender, _liquidity);
        return (token1Amount, token2Amount);
    }

    // 测试操作
    // 1. init函数 传入 100,10
    // 2. addLiquidity函数 传入 100,10
    // 3. dealToken1函数 传入 50
    // 测试结果
    // 未计算手续费前账户应该得到 4个token2
    // 计算千分之三手续费后账户应该得到 3.988个token2
    // 注: 这里忽略了18位精度
    // 1000000000000000000
    // 这里的手续费设计为: 
    // 为了便于满足 x * y = k,在原本需要给账户中的token中直接扣除手续费,与uniswap实际实现略有不同
    // 使用token1交易得到token2
    function dealToken1(uint256 putToken1Amount)
        external
        payable
        hasInited()
        returns (uint256 getToken2Amount)
    {
        uint256 oldToken2Amount = totalLiquidity / token1Supply;
        uint256 newToken1Amount = token1Supply + putToken1Amount;
        uint256 newToken2Amount = totalLiquidity / newToken1Amount;
        // 未收取手续费的token2数量
        uint256 unPayToken2Amount = oldToken2Amount - newToken2Amount;
        // 手续费
        // 直接乘千分之三可能需要考虑精度缺失的问题,这里暂未考虑
        uint256 fee = (unPayToken2Amount * 3 / 1000);
        getToken2Amount = unPayToken2Amount - fee;
        // 确保币对合约拥有足够多的token2
        require(getToken2Amount < token2.balanceOf(address(this)), "the contract don't have enough token2");
        // 滑点 参考:https://blog.csdn.net/chen__an/article/details/119760829
        // 这里为了避免精度缺失过大,故手动乘以1000
        uint256 slipPrice = putToken1Amount / oldToken2Amount * 1000;
        // 转账
        token1.transferFrom(msg.sender, address(this), putToken1Amount);
        token2.transfer(msg.sender, getToken2Amount);
        token2.transfer(FEE_TO_ADDRESS, fee);
        emit getToken(msg.sender, putToken1Amount, getToken2Amount, slipPrice, fee);
    }

    // 使用token2交易得到token1 
    function dealToken2(uint256 putToken2Amount)
        external
        payable
        hasInited()
        returns (uint256 getToken1Amount)
    {
        uint256 oldToken1Amount = token1Supply;
        uint256 newToken2Amount = totalLiquidity / oldToken1Amount + putToken2Amount;
        uint256 newToken1Amount = totalLiquidity / newToken2Amount;
        // 未收取手续费的token1数量
        uint256 unPayToken1Amount = oldToken1Amount - newToken1Amount;
        // 手续费
        // 直接乘千分之三可能需要考虑精度缺失的问题,这里暂未考虑
        uint256 fee = (unPayToken1Amount * 3 / 1000);
        getToken1Amount = unPayToken1Amount - fee;
        // 确保币对合约拥有足够多的token1
        require(getToken1Amount < token1.balanceOf(address(this)), "the contract don't have enough token1");
        // 滑点 参考:https://blog.csdn.net/chen__an/article/details/119760829
        // 这里为了避免精度缺失过大,故手动乘以1000
        uint256 slipPrice = putToken2Amount / oldToken1Amount * 1000;
        // 转账
        token2.transferFrom(msg.sender, address(this), putToken2Amount);
        token1.transfer(msg.sender, getToken1Amount);
        token1.transfer(FEE_TO_ADDRESS, fee);
        emit getToken(msg.sender, putToken2Amount, getToken1Amount, slipPrice, fee);
    }

    // 流动性质押挖矿
    // 个人理解为质押token1,获取对应比例的token2
    // 当其归还借贷的token2数量时,可以拿回当初质押的token1数量
    // 这里忽略无常损失,直接质押多少,还了对应数量的token就可拿回质押的token,且不考虑收取手续费
    // 质押token1挖矿
    function pledgeToken1(uint256 pledgeToken1Amount)
        external
        payable
        hasInited()
        returns (uint256 getToken2Amount)
    {
        // 限制每个用户只能质押一次
        require(pledgeToken1List[msg.sender] == 0 && pledgeToken2List[msg.sender] == 0, "There are transactions under pledge.");
        // 质押得到的token2数量
        getToken2Amount = pledgeToken1Amount * proportion;
        pledgeToken1List[msg.sender] = pledgeToken1Amount;
        // 转账
        token1.transferFrom(msg.sender, address(this), pledgeToken1Amount);
        token2.transfer(msg.sender, getToken2Amount);
        emit pledgeToken(msg.sender, pledgeToken1Amount, getToken2Amount);
    }

    // 质押token2挖矿
    function pledgeToken2(uint256 pledgeToken2Amount)
        external
        payable
        hasInited()
        returns (uint256 getToken1Amount)
    {
        // 限制每个用户只能质押一次
        require(pledgeToken1List[msg.sender] == 0 && pledgeToken2List[msg.sender] == 0, "There are transactions under pledge.");
        // 质押得到的token2数量
        getToken1Amount = pledgeToken2Amount / proportion;
        pledgeToken2List[msg.sender] = pledgeToken2Amount;
        // 转账
        token2.transferFrom(msg.sender, address(this), pledgeToken2Amount);
        token1.transfer(msg.sender, getToken1Amount);
        emit pledgeToken(msg.sender, pledgeToken2Amount, getToken1Amount);
    }

    // 这里暂未考虑质押之后,冻结质押数量的token不能进行其他交易操作
    // 偿还质押的token1赎回token2
    function fetchToken1(uint256 fetchToken1Amount)
        external
        payable
        hasInited()
        returns (bool)
    {
        require(fetchToken1Amount >= pledgeToken1List[msg.sender], "The number of tokens to retrieve is insufficient.");
        // 多余的代币数量
        uint256 extraAmount = fetchToken1Amount - pledgeToken1List[msg.sender];
        // 转账
        token1.transferFrom(msg.sender, address(this), pledgeToken1List[msg.sender]);
        token1.transferFrom(msg.sender, msg.sender, extraAmount);
        token2.transfer(msg.sender, pledgeToken1List[msg.sender] / proportion);
        emit fetchToken(msg.sender, pledgeToken1List[msg.sender], pledgeToken1List[msg.sender] / proportion);
        // 清空
        delete pledgeToken1List[msg.sender];
        return true;
    }

    // 偿还质押的token2赎回token1
    function fetchToken2(uint256 fetchToken2Amount)
        external
        payable
        hasInited()
        returns (bool)
    {
        require(fetchToken2Amount >= pledgeToken2List[msg.sender], "The number of tokens to retrieve is insufficient.");
        // 多余的代币数量
        uint256 extraAmount = fetchToken2Amount - pledgeToken2List[msg.sender];
        // 转账
        token1.transferFrom(msg.sender, address(this), pledgeToken2List[msg.sender]);
        token1.transferFrom(msg.sender, msg.sender, extraAmount);
        token2.transfer(msg.sender, pledgeToken2List[msg.sender] * proportion);
        emit fetchToken(msg.sender, pledgeToken2List[msg.sender], pledgeToken2List[msg.sender] * proportion);
        // 清空
        delete pledgeToken2List[msg.sender];
        return true;
    }
}