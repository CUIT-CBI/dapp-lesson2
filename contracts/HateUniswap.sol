// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HateUniswap is ERC20{
  //两个ERC-20代币
   address public token0;
   address public token1;

  //reserve存储代币数量
   uint public reserve0;
   uint public reserve1;

  //初始金额LP代币
  uint public constant INITIAL_SUPPLY = 10**4;

  //构造交易池
  constructor(address _token0,address _token1) ERC20("LiquidityProvider","LP"){
    token0=_token0;
    token1=_token1;
  }
   

  //添加流动性
  function add(uint amount0,uint amount1) public {

    //将代币转移到池中
    assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
    assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));
  
    uint reserve0After = reserve0 + amount0;
    uint reserve1After = reserve1 + amount1;

    //判断是否为第一个提供流动性的用户，铸造初始金额的LP代币
    if (reserve0 == 0 && reserve1 == 0) {
      _mint(msg.sender, INITIAL_SUPPLY);
    } else {
      //按比例计算份额并铸造等比例的 LP 代币
      //目前LP代币总数
      uint currentSupply = totalSupply();
      //token0、1占比来分配LP代币
      uint newSupplyGivenReserve0Ratio = reserve0After * currentSupply / reserve0;
      uint newSupplyGivenReserve1Ratio = reserve1After * currentSupply / reserve1;
      uint newSupply = Math.min(newSupplyGivenReserve0Ratio, newSupplyGivenReserve1Ratio);
      _mint(msg.sender, newSupply - currentSupply);
    }

     //更新池中代币数量
    reserve0 = reserve0After;
    reserve1 = reserve1After;
  }

  //移出流动性
  function remove(uint liquidity) public {
    assert(transfer(address(this), liquidity));
    //统计目前LPToken
    uint currentSupply = totalSupply();

    //计算移除的LPToken
    uint amount0 = liquidity * reserve0 / currentSupply;
    uint amount1 = liquidity * reserve1 / currentSupply;
    
    //销毁
    _burn(address(this), liquidity);

    //转出
    assert(IERC20(token0).transfer(msg.sender, amount0));
    assert(IERC20(token1).transfer(msg.sender, amount1));
    
    //更新池中代币数量
    reserve0 = reserve0 - amount0;
    reserve1 = reserve1 - amount1;
  }

  // x*y=k
  // (x+dx)*(y-dy)=k 
  //确定交易价格
 function getAmountOut (uint amountIn, address fromToken) public view returns (uint amountOut, uint _reserve0, uint _reserve1) {
    uint newReserve0;
    uint newReserve1;
    uint k = reserve0 * reserve1;

    //公式
    // x (reserve0) * y (reserve1) = k (constant)
    // (reserve0 + amountIn) * (reserve1 - amountOut) = k
    // (reserve1 - amountOut) = k / (reserve0 + amount)
    // newReserve1 = k / (newReserve0)
    // amountOut = newReserve1 - reserve1

    if (fromToken == token0) {
      newReserve0 = amountIn + reserve0;
      newReserve1 = k / newReserve0;
      amountOut = reserve1 - newReserve1;
    } else {
      newReserve1 = amountIn + reserve1;
      newReserve0 = k / newReserve1;
      amountOut = reserve0 - newReserve0;
    }
    
    //更新代币数量
    _reserve0 = newReserve0;
    _reserve1 = newReserve1;
  }

  //swap
  //设置滑点 minAmountOut
    function swap(uint amountIn, uint minAmountOut, address fromToken, address toToken, address to) public {
    require(amountIn > 0 && minAmountOut > 0, 'Amount invalid');
    require(fromToken == token0 || fromToken == token1, 'From token invalid');
    require(toToken == token0 || toToken == token1, 'To token invalid');
    require(fromToken != toToken, 'From and to tokens should not match');

    (uint amountOut, uint newReserve0, uint newReserve1) = getAmountOut(amountIn, fromToken);

    require(amountOut >= minAmountOut, 'not a good transaction');

    //手续费为千分之三
    uint fee = (amountOut * 3) / 1000;

    //交易转账
    assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
    assert(IERC20(toToken).transfer(to, amountOut - fee));

    //转出手续费
    assert(IERC20(toToken).transfer(address(0x0), fee));

    //更新
    reserve0 = newReserve0;
    reserve1 = newReserve1;
  }

 }
