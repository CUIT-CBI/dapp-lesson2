// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
import "./FPair.sol";
import "../libary/V2Pair.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//参考https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
//参考https://blog.csdn.net/chen__an/article/details/119760829
contract FV2Router {
    V2Pair Fpair;
    constructor(address FpairAd) {
    Fpair = V2Pair(FpairAd);
    }

    function addLiquidity(address token1, address token2, uint256 amount1, uint256 amount2, uint256 amount1Min, uint256 amount2Min,address to)
    public
    returns (uint256 amountA,uint256 amountB,uint256 liquidity){
        require(amount1 > 0 && amount2 > 0);
        if (Fpair.getToken0() == address(0) && Fpair.getToken1() == address(0))
        {
            Fpair.initPair(token1, token2);
        }else
        //增加流动性
        (amountA, amountB) = _addLiquidity(amount1,amount2,amount1Min,amount2Min);
        //转账
        _safeTransferFrom(token1, msg.sender, address(Fpair), amountA);
        _safeTransferFrom(token2, msg.sender, address(Fpair), amountB);
        liquidity = V2Pair(Fpair).mint(to);
    }

    //移除流动性
    function removeLiquidity(uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address to) public returns (uint256 amountA, uint256 amountB) {
        require(amountA >= amountAMin && amountA >= amountBMin);
        V2Pair(Fpair).transferFrom(msg.sender, address(Fpair), liquidity);
        (amountA, amountB) = V2Pair(Fpair).burn(to);
    }

    //swap交换（滑点用最小代币数量实现）
    function swapTokenAForTokenB(uint256 amountIn,uint256 amountOutMin,address tokenIn,address tokenOut,address to) 
             public returns (uint256 amount) {
        //确保账户有足够余额
        require(amount >= amountOutMin);
        amount = getAmountOut(amountIn,Fpair.getTokenReserve(tokenIn),Fpair.getTokenReserve(tokenOut));
        _safeTransferFrom(tokenIn,msg.sender,address(Fpair),amountIn);
        if(tokenIn == Fpair.getToken0()) Fpair.swap(0, amount, to);
        if(tokenIn == Fpair.getToken1()) Fpair.swap(amount, 0, to);
    }

    //transfer
    function _safeTransferFrom(address token,address from,address to,uint256 value) public {
        FT(token).transferFrom(from, to, value);
    }
    //Add流动性
    function _addLiquidity(uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin) 
             internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = Fpair.getReserves();

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA,reserveB);

        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal > amountBMin);
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = quote(amountBDesired,reserveB,reserveA);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal > amountAMin);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    // 初始化
     function quote( uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn != 0, "Amount is unenough");
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is unenough");
        amountOut = (amountIn * reserveOut) / reserveIn;
    }

    // 根据输入，计算扣除千分之三手续费后的输出
    // (x + x1) * (y - y1) = x * y
    // y1 = (y * x1) / (x + x1)
    function getAmountOut(uint256 amountIn,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn != 0, "Amount is unenough");
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is unenough");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    // scope for reserve{0,1}Adjusted, avoids stack too deep errors
    //uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
    //uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
    //require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
    }
     function getAmountIn(uint256 amountOut,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amountIn) {
        require(amountOut != 0, "Amount is unenough");
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is unenough");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }
   
}
