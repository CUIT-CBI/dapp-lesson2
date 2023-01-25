// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract factory is ERC20 {
    //交易对 token1、token2
    address public token0;
    address public token1;

    //token1、token2余额
    uint public reserve0;
    uint public reserve1;

    uint public constant INITIAL_SUPPLY = 10**5;

    constructor(address _token0, address _token1) ERC20("LP", "LP") {
        token0 = _token0;
        token1 = _token1;
}

//增加流动性
function addLiquidity(uint amount0, uint amount1) public {
    assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

    uint reserve0After = reserve0 + amount0;
    uint reserve1After = reserve1 + amount1;
    //铸造LP代币，为流动性提供者为交易池做贡献的证明
    if (reserve0 == 0 && reserve1 == 0) {
      _mint(msg.sender, INITIAL_SUPPLY);
    } else {
      uint currentSupply = totalSupply();
      uint newSupplyGivenReserve0Ratio = reserve0After * currentSupply / reserve0;
      uint newSupplyGivenReserve1Ratio = reserve1After * currentSupply / reserve1;
      uint newSupply = Math.min(newSupplyGivenReserve0Ratio, newSupplyGivenReserve1Ratio);
      _mint(msg.sender, newSupply - currentSupply);
    }

    reserve0 = reserve0After;
    reserve1 = reserve1After;
}

//移除流动性
function removeLiquidity(uint liquidity) public {
    assert(transfer(address(this), liquidity));

    uint currentSupply = totalSupply();
    uint amount0 = liquidity * reserve0 / currentSupply;
    uint amount1 = liquidity * reserve1 / currentSupply;
    //销毁LP代币
    _burn(address(this), liquidity);

    assert(IERC20(token0).transfer(msg.sender, amount0));
    assert(IERC20(token1).transfer(msg.sender, amount1));
    reserve0 = reserve0 - amount0;
    reserve1 = reserve1 - amount1;
}

/**
*1.k=x*y 换算token之间的交换关系
*2.交易费千分之三
**/
function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0 * reserve1;

    // x (reserve0) * y (reserve1) = k (constant)
    // (reserve0 + amountIn) * (reserve1 - amountOut) = k
    // (reserve1 - amountOut) = k / (reserve0 + amount)
    // newReserve1 = k / (newReserve0)
    // amountOut = newReserve1 - reserve1


    //计算可得到的代币数
    if (fromToken == token0) {
      newReserve0 = amountIn + reserve0;
      newReserve1 = k / newReserve0;
      newReserve1 = newReserve1;
      amountOut = reserve1 - newReserve1;
      amountOut = amountOut * 997/1000;
    } else {
      newReserve1 = amountIn + reserve1;
      newReserve0 = k / newReserve1;
      amountOut = reserve0 - newReserve0;
      amountOut = amountOut * 997/1000;
    }

    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
}

//交易功能，滑点minAmountOut
function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
    require(fromToken == token0 || fromToken == token1, 'From token invalid');
    require(toToken == token0 || toToken == token1, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    //调用getAmountOut函数
    (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut);

    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut));

    reserve0 = newReserve0;
    reserve1 = newReserve1;
  }
}