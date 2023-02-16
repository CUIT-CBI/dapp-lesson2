// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./tokenPair.sol";
import "hardhat/console.sol";


contract uniswapV2Router {

    uniswapV2Pair pair;

    constructor(address pairAddress) {
        pair = uniswapV2Pair(pairAddress);
    }

    // 增加流动性
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256, uint256, uint256) {
        require(pair.getToken0()  != address(0) && pair.getToken1() != address(0), "pair is empty");

        uint256 reserveA = pair.getTokenReserve(tokenA);
        uint256 reserveB = pair.getTokenReserve(tokenB);

        uint256 amountA = 0;
        uint256 amountB = 0;

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            amountA = (amountBDesired * reserveA) / reserveB;
            amountB = (amountADesired * reserveB) / reserveA;
            console.log("amountA:",amountA);
            console.log("amountB:",amountB);
            require(amountA > amountAMin,"amountA should be greater than amountAMin");
            require(amountB > amountBMin,"amountB should be greater than amountBMin");
        }

        _safeTransferFrom(tokenA, msg.sender, address(pair), amountA);
        _safeTransferFrom(tokenB, msg.sender, address(pair), amountB);

        uint256 liquidity = uniswapV2Pair(pair).mintLP(to);
        return (amountA, amountB, liquidity);
    }

    // 移除流动性
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        uniswapV2Pair(pair).transferFrom(msg.sender, address(pair), liquidity);
        (amountA, amountB) = uniswapV2Pair(pair).burnLP(to);
        require(amountA >= amountAMin && amountA >= amountBMin, "the amount you can get should be greater than min");
    }

    // 交易功能
    // 滑点
    function swapExactTokenForToken(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        address to,
        uint Slippage
    ) public returns (uint256 amount) {

        console.log("amountIn", amountIn);
        amount = getAmountOut(
            amountIn,
            pair.getTokenReserve(tokenIn),
            pair.getTokenReserve(tokenOut)
        );

        uint256 amountOutMin = Slippage != 0 ? amountOut * (100 - Slippage) / 100 : amountOut;
        console.log("amountOutMin:",amountOutMin);
        require(amount >= amountOutMin, "the amount you can out should be greater than min");

        _safeTransferFrom(tokenIn, msg.sender, address(pair), amountIn);

        if(tokenIn == pair.getToken0()) pair.swap(0, amount, to);
        if(tokenIn == pair.getToken1()) pair.swap(amount, 0, to);
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        FT(token).transferFrom(from, to, value);
    }

    // 计算千分之三手续费
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn != 0, "amountIn should not be 0");
        require(reserveIn != 0 && reserveOut != 0, "reserveIn and reserveOut should not be 0");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }
}
