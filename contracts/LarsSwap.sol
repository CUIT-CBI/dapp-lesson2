// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LarsSwap is ERC20 {
    address public immutable token0;
    address public immutable token1;
    uint256 public reserve0;//token0的存储量
uint256 public reserve1;//token1的存储量
uint256 private balance0;//token0的存储量
uint256 private balance1;//token1的余额

    constructor(address _token0,address _token1)ERC20("LiquidityProvider","LP"){
        token0 = _token0;
        token1 = _token1;
    }

    //增加流动性
    function addLiquidity(uint256 amount0,uint256 amount1) public {
        assert(IERC20(token0).transferFrom(msg.sender, address(this), amount0));
        assert(IERC20(token1).transferFrom(msg.sender, address(this), amount1));
        reserve0 += amount0;
        reserve1 += amount1;
        _mint(msg.sender,amount0 * amount1);
    }

    //移除流动性
    function removeLiquidity(uint256 liquidity) public {
        require(liquidity <= balanceOf(msg.sender));
        assert(transfer(address(this), liquidity));
        uint amount0 = liquidity * reserve0 / totalSupply(); 
        uint amount1 = liquidity * reserve1 / totalSupply();
        _burn(address(this), liquidity); 
        assert(IERC20(token0).transfer(msg.sender, amount0)); 
        assert(IERC20(token1).transfer(msg.sender, amount1)); 
        reserve0 -= amount0; 
        reserve1 -= amount1; 
    }

    //交易功能、滑点
function swap(uint256 amountIn,uint256 minAmountOut,address fromToken,address toToken,address to)
 public {
        uint256 serviceFee = amountIn * 3 / 1000;
        uint256 amountOut = getAmountOut(amountIn - serviceFee,fromToken);
        require(amountOut >= minAmountOut);
        assert(IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn));
        assert(IERC20(toToken).transfer(to, amountOut));
        if(fromToken == token0){
            reserve0 += amountIn;
            reserve1 -= amountOut; 
        }else if(fromToken == token1){
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
    }

    //由输入的代币及其数量计算输出的代币的数量
    function getAmountOut(uint256 amountIn,address fromToken) private view returns(uint256) {
        require(reserve0 > 0 && reserve1 > 0,"token reserve isn't enough!");
        uint256 k = reserve0 * reserve1;
        uint256 amountOut;
        if(fromToken == token0){
            uint256 newReserve0 = reserve0 + amountIn;
            uint256 newReserve1 = k / newReserve0;
            amountOut = reserve1 - newReserve1;
        }else if(fromToken == token1){
            uint256 newReserve1 = reserve1 + amountIn;
            uint256 newReserve0 = k / newReserve1;
            amountOut = reserve0 - newReserve0;
        }
        return amountOut;
    }
}
