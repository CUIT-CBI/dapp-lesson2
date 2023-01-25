//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HHLSwapPool is ERC20 {
//   两种代币
  address public HHL;
  address public hhl;

// 合约地址  

  uint public reserve0;
  uint public reserve1;

  uint public constant INITIAL_SUPPLY = 10**5;

// 构造交易池
  constructor(address _HHL, address _hhl) ERC20("HHLLiquidityProvider", "LP") {
    HHL = _HHL;
    hhl = _hhl;
  }

//   增加流动性
  function add(uint amount0, uint amount1) public {
    // 用户把代币转移到交易池
    assert(IERC20(HHL).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(hhl).transferFrom(msg.sender, address(this), amount1));

    uint reserve0After = reserve0 + amount0;
    uint reserve1After = reserve1 + amount1;

    
    if (reserve0 == 0 && reserve1 == 0) {
      // 铸造初始金额的LP代币  
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

//    移除流动性
  function remove(uint liquidity) public {
    assert(transfer(address(this), liquidity));

    uint currentSupply = totalSupply();
    uint amount0 = liquidity * reserve0 / currentSupply;
    uint amount1 = liquidity * reserve1 / currentSupply;

    _burn(address(this), liquidity);

    assert(IERC20(HHL).transfer(msg.sender, amount0));
    assert(IERC20(hhl).transfer(msg.sender, amount1));
    reserve0 = reserve0 - amount0;
    reserve1 = reserve1 - amount1;
  }


  function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0 * reserve1;
// 手续费
    uint commission;

    if (fromToken == HHL) {
      newReserve0 = amountIn + reserve0;
      newReserve1 = k / newReserve0;
      amountOut = reserve1 - newReserve1;
      //   减去手续费
      amountOut =amountOut -amountOut*commission/10000;
    } else {
      newReserve1 = amountIn + reserve1;
      newReserve0 = k / newReserve1;
      amountOut = reserve0 - newReserve0;
      amountOut =amountOut -amountOut*commission/10000;
    }
    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
  }

  function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
    require(fromToken == HHL || fromToken == hhl, 'From token invalid');
    require(toToken == HHL || toToken == hhl, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut, 'Slipped... on a banana');

    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut));

    reserve0 = newReserve0;
    reserve1 = newReserve1;
  }

  
}
