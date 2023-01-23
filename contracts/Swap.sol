/*
1、实验目的：
熟练掌握ERC20标准，熟悉基于xy=k的AMM实现原理，能实现增加/移出流动性，实现多个token的swap
2、参考教程
* 了解熟悉AMM相关原理：[精通Uniswap](https://learnblockchain.cn/article/1448)
* 可以借鉴的代码与教程：
    * [Uniswap v2源码](https://github.com/Uniswap/v2-core/tree/master/contracts)
    * [构建一个简单的交易所](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)
    * [Uniswap - 智能合约V2代码导读](https://learnblockchain.cn/article/1480)
    * [UNISWAP-V2 合约概览](https://ethereum.org/zh/developers/tutorials/uniswap-v2-annotated-code/)
* 难点：**手续费、滑点功能**
* 加分项前端对接：[web3-react](https://github.com/Uniswap/web3-react)

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "FT.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap is FT {
//新铸造两个代币
  address public token0;
  address public token1;

//初始化代币余额
  uint public reserve0;
  uint public reserve1;
//初始化服务费
  uint public serviceCharge0;
  uint public serviceCharge1;
//初始化总量
  uint public constant total = 10000;

  constructor(address _token0, address _token1) FT("ZXL", "ZXL") {
    token0 = _token0;
    token1 = _token1;
  }
//增加流动性

  function add(uint amount0, uint amount1) public {
    assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));

    uint Reserve0 = reserve0 + amount0;
    uint Reserve1 = reserve1 + amount1;

    if (reserve0 == 0 && reserve1 == 0) {
      _mint(msg.sender, total);
    } else {
      uint currentSupply = totalSupply();
      uint newReserve0 = Reserve0 * currentSupply / reserve0;
      uint newReserve1 = Reserve1 * currentSupply / reserve1;
      uint newSupply = Math.min(newReserve0, newReserve1);
      _mint(msg.sender, newSupply - currentSupply);
    }

    reserve0 = Reserve0;
    reserve1 = Reserve1;
  }

//移除流动性

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
    require(amountIn > 0 && minAmountOut > 0);
    require(fromToken == token0 || fromToken == token1);
    require(toToken == token0 || toToken == token1);
    require(fromToken != toToken);

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
