//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapPool is ERC20 {
  address public token0;
  address public token1;

  //池的拥有者
  address public owner;

  uint public reserve0;
  uint public reserve1;



  //初始化
  uint256 public INITIAL_SUPPLY = 10**5;

  constructor(address _token0, address _token1) ERC20("SwapPool", "SP") {
    token0 = _token0;
    token1 = _token1;
    owner = msg.sender;
  }


  function addMobility(uint amount0, uint amount1) public {
    assert(ERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(ERC20(token1).transferFrom(msg.sender, address(this), amount1));

    uint reserve0After = reserve0 + amount0;
    uint reserve1After = reserve1 + amount1;

    if (reserve0 == 0 && reserve1 == 0) {
      _mint(msg.sender, INITIAL_SUPPLY);
    } else {
      uint currentSupply = totalSupply();
      uint newSupply0 = reserve0After * currentSupply / reserve0;
      uint newSupply1 = reserve1After * currentSupply / reserve1;
      uint newSupply = Math.min(newSupply0, newSupply1);
      _mint(msg.sender, newSupply - currentSupply);
    }

    reserve0 = reserve0After;
    reserve1 = reserve1After;
  }


  function removeMobility(uint mobility ) public {
    assert(transfer(address(this), mobility));

    uint currentSupply = totalSupply();
    uint amount0 = mobility * reserve0 / currentSupply;
    uint amount1 = mobility * reserve1 / currentSupply;

    _burn(address(this), mobility);

    assert(IERC20(token0).transfer(msg.sender, amount0));
    assert(IERC20(token1).transfer(msg.sender, amount1));
    reserve0 = reserve0 - amount0;
    reserve1 = reserve1 - amount1;
  }


  function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1,uint expect) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0 * reserve1;
    uint256 rate;
    if (fromToken == token0) {
      newReserve0 = amountIn + reserve0;
      newReserve1 = k / newReserve0;
      amountOut = reserve1 - newReserve1;
      if(reserve0>=reserve1){
        rate = reserve0/reserve1;
         expect = amountIn / rate;
        } else {
        rate = (reserve1*100)/reserve0;
         expect = (amountIn * rate)/100;
        }  

    } else {

      newReserve1 = amountIn + reserve1;
      newReserve0 = k / newReserve1;
      amountOut = reserve0 - newReserve0;
      if(reserve0>=reserve1){
          rate = reserve0/reserve1;
           expect = amountIn / rate;
        } else {
            rate = (reserve1*100)/reserve0;
            expect = (amountIn * rate)/100;
        }

    }

    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
  }



  function swap(uint amountIn, uint point,address fromToken, address toToken, address to) public {
    require(amountIn > 0 , 'Amount invalid');
    require(fromToken == token0 || fromToken == token1, 'From token invalid');
    require(toToken == token0 || toToken == token1, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    (uint amountOut, uint newReserve0, uint newReserve1,uint expect) = getAmountOut(amountIn, fromToken);
    //滑点
    uint split = (expect - amountOut) * 100 / expect;
    require(split<=point,"Spiled...");

    assert(ERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));

    //手续费
    uint256 fee =  (amountOut/1000)*3;
    assert(ERC20(toToken).transfer(to, amountOut-fee));
    assert(ERC20(toToken).transfer(owner,fee));

    reserve0 = newReserve0;
    reserve1 = newReserve1;
  }
}
