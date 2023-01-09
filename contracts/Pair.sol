// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FT.sol";
import "./Math.sol";
import "./SafeMath.sol";

// @dev 简单设计实现uniswap合约 功能:增加/移出流动性、交易功能、实现手续费功能，千分之三手续费、实现滑点功能
// @note 本合约添加/移除流动性不收取手续费,只有交易收取千分之三手续费
// @author Weihaoming
contract Pair {
    
    event inited(uint256 proportion);
    event LiquidityAdded(address indexed opeartor, uint256 indexed liquidity);
    event LiquidityRemoved(address indexed opeartor, uint256 indexed liquidity);
    event getToken1(
        address indexed opeartor, 
        uint256 putToken2Amount, 
        uint256 getToken1Amount, 
        uint256 slipPrice, 
        uint256 fee
    );
    event getToken2(
        address indexed opeartor, 
        uint256 putToken1Amount, 
        uint256 getToken2Amount, 
        uint256 slipPrice, 
        uint256 fee
    );

    // 手续费收取地址,默认为Remix提供的最后一个账户地址
    address public constant FEE_TO_ADDRESS =  0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    // 合约拥有者
    address public owner;
    // token1合约地址
    FT public token1;
    // token2合约地址
    FT public token2;
    uint256 public liquidity;
    // 总流动性 (x * y)
    uint256 public totalLiquidity;
    // token1总量
    uint256 public token1Supply;
    // 比例
    uint256 public proportion;
    // 用户地址 => liquidity
    mapping(address => uint256) public LPTokens;
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
    function dealToken1(uint256 putToken1Amount)
        external
        payable
        hasInited()
        returns(uint256 getToken2Amount)
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
        require(getToken2Amount < token2.balanceOf(address(this)), "the contract don't have enough token2");
        // 滑点 参考:https://blog.csdn.net/chen__an/article/details/119760829
        // 这里为了避免精度缺失过大,故手动乘以1000
        uint256 slipPrice = putToken1Amount / oldToken2Amount * 1000;
        // 转账
        token1.transferFrom(msg.sender, address(this), putToken1Amount);
        token2.transfer(msg.sender, getToken2Amount);
        token2.transfer(FEE_TO_ADDRESS, fee);
        emit getToken2(msg.sender, putToken1Amount, getToken2Amount, slipPrice, fee);
    }
}