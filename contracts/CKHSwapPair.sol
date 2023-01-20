// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FT.sol";

// ## 实验内容
// ### 1. 增加/移出流动性                      30分
// ### 2. 交易功能                            30分
// ### 3. 实现手续费功能，千分之三手续费          10分
// ### 4. 实现滑点功能                         15分
// ### 5. 实现部署脚本                         15分

contract CKHSwapPair is FT {
    address public token1;//第一种货币
    address public token2;//第二种货币
    address public factory;
    uint256 public token1Balance;
    uint256 public token2Balance;
    uint256 public reserve1;
    uint256 public reserve2;
  
    constructor(address _token1, address _token2) FT("CKHSwap LPToken", "LP") {
        token1 = _token1;
        token2 = _token2;
        factory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "This is not facroty!");
        _;
    }

    //增加流动性
    function addLiquidity(uint256 count) external {
        address _account = msg.sender;
        uint256 currentTotalSupply = totalSupply();
        require(currentTotalSupply > 0, "Invalid LP token count reserved!");
        uint256 _token1Count = reserve1 * count / currentTotalSupply;
        uint256 _token2Count = reserve2 * count / currentTotalSupply;
        ERC20(token1).transferFrom(_account, address(this), _token1Count);
        ERC20(token2).transferFrom(_account, address(this), _token2Count);
        super._mint(_account, count);
        _updateReserves();
    }

    //移出流动性
    function removeLiquidity(uint256 count) external {
        address account = msg.sender;
        uint256 currentLPTotalSupply = totalSupply();
        require(currentLPTotalSupply > count, "Invalid token count to remove!");
        require(balanceOf(account) >= count, "You don't have enough token!");
        uint256 _token0Count = reserve1 * count / currentLPTotalSupply;
        uint256 _token1Count = reserve2 * count / currentLPTotalSupply;
        super._burn(account, count);
        ERC20(token1).transfer(account, _token0Count);
        ERC20(token2).transfer(account, _token1Count);
        _updateReserves();
    }

    //交换和滑点功能，互换
    //token1交换token2
    function token1SwapToken2(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token1Balance,token2Balance);
        require(amountGet>=minGet,"error!");
        token1Balance += amountIn;
        token2Balance -= amountGet;
        require(FT(token1).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token2).transferFrom(address(this),msg.sender,amountGet));
    }
    
    //token2交换token1
    function token2SwapToken1(uint256 amountIn,uint256 minGet)public{
        uint256 amountGet = getAmount(amountIn,token2Balance,token1Balance);
        require(amountGet>=minGet,"error!");
        token2Balance += amountIn;
        token1Balance -= amountGet;
        require(FT(token2).transferFrom(msg.sender,address(this),amountIn));
        require(FT(token1).transferFrom(address(this),msg.sender,amountGet));
    }

    //千分之三的手续费
    function getAmount(uint256 inputAmount,uint256 inputBal,uint256 outputBal) private pure returns (uint256) {
        uint256 commission = inputAmount * 997;
        uint256 numerator = commission * outputBal;
        uint256 denominator = (inputBal * 1000) + commission;
        return numerator / denominator;
    }

    function _updateReserves() private {
        reserve1 = ERC20(token1).balanceOf(address(this));
        reserve2 = ERC20(token2).balanceOf(address(this));
    }
}
