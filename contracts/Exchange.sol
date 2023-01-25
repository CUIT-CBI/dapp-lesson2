// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./UniswapV2Pair.sol";
import "./IUniswapV2Pair.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//参考https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
contract FV2Router {
    IUniswapV2Pair UniswapV2Pair;
    constructor(address FpairAd) {
    UniswapV2Pair = IUniswapV2Pair(FpairAd);
    }

    function addLiquidity(
        address token1, 
        address token2, 
        uint256 amount1, 
        uint256 amount2, 
        uint256 amount1Min, 
        uint256 amount2Min,
        address to) public returns (uint256 amountA,uint256 amountB,uint256 liquidity){
        require(amount1 > 0 && amount2 > 0);
        if (UniswapV2Pair.token0() == address(0) && UniswapV2Pair.token1() == address(0))
        {
            UniswapV2Pair.initialize(token1, token2);
        }else
        //增加流动性
        (amountA, amountB) = _addLiquidity(amount1,amount2,amount1Min,amount2Min);
        
        liquidity = IUniswapV2Pair(UniswapV2Pair).mint(to);
    }

    //移除流动性
    function removeLiquidity(uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address to) public returns (uint256 amountA, uint256 amountB) {
        require(amountA >= amountAMin && amountA >= amountBMin);
        IUniswapV2Pair(UniswapV2Pair).transferFrom(msg.sender, address(UniswapV2Pair), liquidity);
        (amountA, amountB) = IUniswapV2Pair(UniswapV2Pair).burn(to);
    }

    //swap交换（滑点用最小代币数量实现）
    function swapTokenAForTokenB(uint256 amountIn,uint256 amountOutMin,address tokenIn,address tokenOut,address to) 
             public returns (uint256 amount) {
        //确保账户有足够余额
        require(amount >= amountOutMin);
        amount = getAmountOut(amountIn,UniswapV2Pair.getTokenReserve(tokenIn),UniswapV2Pair.getTokenReserve(tokenOut));
        _safeTransferFrom(tokenIn,msg.sender,address(UniswapV2Pair),amountIn);
        if(tokenIn == UniswapV2Pair.token0()) UniswapV2Pair.swap(0, amount, to);
        if(tokenIn == UniswapV2Pair.token1()) UniswapV2Pair.swap(amount, 0, to);
    }

    //transfer
    function _safeTransferFrom(address token,address from,address to,uint256 value) public {
        FT(token).transferFrom(from, to, value);
    }
    //Add流动性
    function _addLiquidity(uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin) 
             internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB, ) = UniswapV2Pair.getReserves();

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
    // xy = k
    // (x + Δx) * (y - Δy) = x * y
    // Δy = (y * Δx) / (x + Δx)
    function getAmountOut(uint256 amountIn,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amountOut) {
        // require(amountIn != 0, "Amount is unenough");
        // require(reserveIn != 0 && reserveOut != 0, "Liquidity is unenough");
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
     function getAmountIn(uint256 amountOut,uint256 reserveIn,uint256 reserveOut) public pure returns (uint256 amountIn) {
        require(amountOut != 0, "Amount is unenough");
        require(reserveIn != 0 && reserveOut != 0, "Liquidity is unenough");
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

}