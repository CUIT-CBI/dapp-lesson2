// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./wkSwap.sol";
@@ -8,20 +9,19 @@ contract Factory  {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor() public {}

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
    function createPair(address tokenA, address tokenB) external returns(address) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");
        Swap swap = new Swap(tokenA, tokenB);
        getPair[token0][token1] = swap;
        getPair[token1][token0] = swap;
        allPairs.push(swap);
        getPair[token0][token1] = address(swap);
        getPair[token1][token0] = address(swap);
        allPairs.push(address(swap));
        return address(swap);
    }
}
