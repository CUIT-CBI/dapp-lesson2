pragma solidity ^0.8.0;

import "contracts/FT.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LooneySwapPool is FT {
  address public token0;
  address public token1;


  uint public reserve0;

  uint public serviceCharge0;

  uint public reserve1;

  uint public serviceCharge1;

  uint public constant INITIAL_SUPPLY = 10**5;

  constructor(address _token0, address _token1) FT("LooneyLiquidityProvider", "LP") {
    token0 = _token0;
    token1 = _token1;
  }
  function add(uint amount0, uint amount1) public {
    assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

    uint reserve0After = reserve0 + amount0;
    uint reserve1After = reserve1 + amount1;

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
  function remove(uint liquidity) public {
    assert(transfer(address(this), liquidity));

    uint currentSupply = totalSupply();
    uint amount0 = liquidity * reserve0 / currentSupply;
    uint amount1 = liquidity * reserve1 / currentSupply;
    uint charge0 = liquidity * serviceCharge0 / (serviceCharge0 + serviceCharge1);
    uint charge1 = liquidity * serviceCharge1 / (serviceCharge0 + serviceCharge1);
    _burn(address(this), liquidity);

    assert(IERC20(token0).transfer(msg.sender, amount0));
    assert(IERC20(token0).transfer(msg.sender, charge0));
    assert(IERC20(token1).transfer(msg.sender, amount1));
     assert(IERC20(token1).transfer(msg.sender, charge1));
    reserve0 = reserve0 - amount0;
    serviceCharge0 = serviceCharge0 - charge0;
    reserve1 = reserve1 - amount1;
    serviceCharge1 = serviceCharge1 - charge1;
  }
  function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1, uint _serviceCharge0, uint _serviceCharge1) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0 * reserve1;
    if (fromToken == token0) {
      newReserve0 = amountIn + reserve0;
      newReserve1 = k / newReserve0;
      amountOut = (reserve1 - newReserve1)*997/1000;
      _serviceCharge1 = (reserve1 - newReserve1)*3/1000;
    } else {
      newReserve1 = amountIn + reserve1;
      newReserve0 = k / newReserve1;
      amountOut = (reserve0 - newReserve0)*997/1000;
      _serviceCharge0 = (reserve0 - newReserve0)*3/1000;
    }

    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
  }
  function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
    require(fromToken == token0 || fromToken == token1, 'From token invalid');
    require(toToken == token0 || toToken == token1, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    (uint amountOut, uint newReserve0, uint newReserve1, uint newServiceCharge0, uint newServiceCharge1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut);

    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut));

    reserve0 = newReserve0;
    reserve1 = newReserve1;

    serviceCharge0 = serviceCharge0 + newServiceCharge0;
    serviceCharge1 = serviceCharge1 + newServiceCharge1;
  }
}
