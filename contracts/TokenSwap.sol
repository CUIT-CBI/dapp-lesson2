// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./FT.sol";
import "./Math.sol";

contract swap {
    address public owner;

    address public token1;// Token1合约地址
    address public token2;// Token2合约地址
    
    uint256 public token1Amount;// Token1总量
    uint256 public token2Amount;// Token2总量
    
    uint public  liquidity; //x * y = k,总流动性

    uint256 public sign = 0;// 是否初始化池子,未初始化为1

    //在构造函数中声明并且保存这两个地址
    //这个合约本身也会产生一个 erc-20 代币
    //它依据用户提供流动性的多少来分配
    //是流动性提供者为交易池做贡献的证明。我们称之为 LP（Liquidity Provider）代币。
    constructor(address _token1, address _token2)ERC20("LiquidityProvider", "LP") {        
        token1 = _token1;
        token2 = _token2;
        owner = msg.sender;
    }

    // 判断是否初始化池子
    modifier Inited {
        require(sign == 1,"Please init firstly");
        _;
    }
    function changeAmount() public {
        token1Amount = ERC20(token1).balanceOf(address(this));
        token2Amount = ERC20(token2).balanceOf(address(this));
    }

    // 初始化池子
    function init(uint256 token1Amount, uint256 token2Amount) public payable  {
        require (owner == msg.sender);
        require(sign == 0);
        // 更新sign ，表示已初始化池子
        sign = 1;
        //币的数量发生变化
        token1Amount = token1Amount;
        token2Amount = token2Amount;
        //将代币转移至池中
        ERC20(token1).transferFrom(msg.sender, address(this), token1Amount);
        ERC20(token2).transferFrom(msg.sender, address(this), token2Amount);
        
        uint initLiquidity = sqrt(_amount0 * _amount1);
        //铸造初始金额的 LP 代币
        _mint(msg.sender, initLiquidity);
                
    }

    // 增加流动性
     function addLiquidity(address _token, uint256 _amount) 
        external
        Inited
        returns (uint256) 
    {
        require(_token == token1 || _token == token2,"Invalid address!");
        uint amount1;
        uint amount2;
       //
        if(_token == token1){
            amount1 = _amount;
            
            amount2 = token2Amount * amount1 / token1Amount;            
        } else {
            amount2 = _amount;
            
            amount1 = token1Amount * amount2 / token2Amount;
        }

        ERC20(token0).transferFrom(msg.sender, address(this), amount1);
        ERC20(token1).transferFrom(msg.sender, address(this), amount2);

        
        liquidity = min(totalSupply() * amount1 / token1Amount, totalSupply() * amount2 / token2Amount);
        //造初始金额的 LP 代币
        _mint(msg.sender, liquidity);

        changeAmount();

        return liquidity;
    }

    
    //交换

    function swapToken1(uint256 SwapToken1Amount)
        external
        payable
        Inited
        returns (uint256 getToken2Amount)
    {
        ERC20(token1).transferFrom(msg.sender, address(this), SwapToken1Amount);
        getToken2Amount = (token2Amount - (token1Amount * token2Amount) / (token1Amount + SwapToken1Amount))  * 997 / 1000;   // 千分之三手续费
        ERC20(token2).transfer(msg.sender, getToken2Amount);
        changeAmount();
    }
        
    

    // 使用token2交易得到token1 
    function swapToken2(uint256 SwapToken2Amount)
        external
        payable
        Inited
        returns (uint256 getToken1Amount)
    {
        ERC20(token2).transferFrom(msg.sender, address(this), SwapToken2Amount);
        // 千分之三手续费，先乘997再除以1000得到的数没有小数点
        getToken1Amount = (token1Amount - (token2Amount * token1Amount) / (token2Amount + SwapToken2Amount))  * 997 / 1000;   
        ERC20(token1).transfer(msg.sender, getToken1Amount);

        changeAmount();
    }

    //设置了滑点下的swap
    //设置了一个限制
    //使得用户认为不合理的交易不会被执行
    function SwapUnderslip(address _token, uint256 _inputAmount, uint256 _minTokens) external returns (uint256){
        require(_token == token1 || _token == token2);
        uint256 expectGetAmount;
        uint256 actualGetAmount;
        //滑点
        uint256 slipPoint = 5;
        if(_token == token1){
            expectGetAmount = token2Amount * _inputAmount / token1Amount;
            actualGetAmount = swapToken1(_inputAmount, _minTokens);
        }
        if(_token == token1){
            expectGetAmount =  token1Amount * _inputAmount /token2Amount;
            actualGetAmount = swapToken2(_inputAmount, _minTokens);
        }
        uint256 slip = (expectGetAmount - actualGetAmount) * 1000 / expectGetAmount;
        //不能超过设置的滑点
        require(slip <= slipPoint);

        changeAmount();
    }
    // 移除流动性
    function removeLiquidity(uint256 _liquidity) 
        external 
        payable 
        Inited
        returns (uint256, uint256)
    {
        require(_liquidity > 0 );
        
        uint256 balance1 = ERC20(token1).balanceOf(address(this));
        uint256 balance2 = ERC20(token2).balanceOf(address(this));

        //计算这部分 LP 代币在池子中代表的 token0 和 token1 的数量
        amount1 = _liquidity * balance1 / totalSupply();       
        amount2 = _liquidity * balance2 / totalSupply();

        //销毁该用户的LP代币
        _burn(msg.sender, _liquidity);

        //将 token0 和 token1 归还给该用户
        ERC20(token1).transfer(msg.sender, amount1);
        ERC20(token2).transfer(msg.sender, amount2);

        changeAmount();

        return (amount1, amount2);
    }


}





