// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YYY is ERC20 {
    //为整个交易池，添加交易对
    address public tokenA;
    address public tokenB;

    //创建两个uint，记录币对余额
    uint public reserveA;
    uint public reserveB;

    uint public constant INITIAL_SUPPLY = 10**6;

    //构造函数，初始化输入token对，初始化创建LP代币
    constructor(address _tokenA, address _tokenB) ERC20("LP", "[LP]") {
        tokenA = _tokenA;
        tokenB = _tokenB;
}

//增加流动性，让交易对进入pool
function add(uint amountA, uint amountB) public {

    assert(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA));
    assert(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB));

    uint reserveAAfter = reserveA + amountA;
    uint reserveBAfter = reserveB + amountB;
    //铸造LP代币，证明token的增加
    if (reserveA == 0 && reserveB == 0) {
      _mint(msg.sender, INITIAL_SUPPLY);
    } else {
      uint Supply = totalSupply();
      uint newSupplyGivenReserveA = reserveAAfter * Supply / reserveA;
      uint newSupplyGivenReserveB = reserveBAfter * Supply / reserveB;
      uint newSupply = Math.min(newSupplyGivenReserveA, newSupplyGivenReserveB);
      _mint(msg.sender, newSupply - Supply);
    }

    reserveA = reserveAAfter;
    reserveB = reserveBAfter;
}

//移除流动性
function remove(uint liquidity) public {
    assert(transfer(address(this), liquidity));

    uint currentSupply = totalSupply();
    uint amountA = liquidity * reserveA / currentSupply;
    uint amountB = liquidity * reserveB / currentSupply;
    //销毁LP代币
    _burn(address(this), liquidity);

    assert(IERC20(tokenA).transfer(msg.sender, amountA));
    assert(IERC20(tokenB).transfer(msg.sender, amountB));
    reserveA = reserveA - amountA;
    reserveB = reserveB - amountB;
}

//Swap功能，滑点实现，调用getAmountOut方法
function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0);
    require(fromToken == tokenA || fromToken == tokenB);
    require(toToken == tokenA || toToken == tokenB);
    require(fromToken != toToken);

    //调用函数
    (uint amountOut, uint newReserveA, uint newReserveB) = getAmountOut(amountIn, fromToken);
    require(amountOut >= minAmountOut);
    //转移token
    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut));

    reserveA = newReserveA;
    reserveB = newReserveB;
  }

/**
*函数：换算token之间的利率，返回扣除fee过后的余额
*1.k=x*y
*2.交易费千分之三
**/
function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserveA, uint _reserveB) {
    uint newReserveA;
    uint newReserveB;
    uint k = reserveA * reserveB;

    //分析两种情况(A=>B,B=>A)
    if (fromToken == tokenA) {
      newReserveA = amountIn + reserveA;
      newReserveB = k / newReserveA;
      amountOut = reserveB - newReserveB;
      amountOut = amountOut * 997/1000;//避免浮点数
    } else {
      newReserveB = amountIn + reserveB;
      newReserveA = k / newReserveB;
      amountOut = reserveA - newReserveA;
      amountOut = amountOut * 997/1000;
    }

    _reserveA = newReserveA;
    _reserveB = newReserveB;
}
}