// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SwapPair.sol";

contract SwapFactory {
    mapping(address => mapping(address => address)) public pairs;

    function crPair(address token0, address token1) public returns (address) {
        SwapPair pair = new SwapPair(token0, token1);
        pairs[token0][token1] = address(pair);
        pairs[token1][token0] = address(pair);

        return address(pair);
    }

    function initPair(address _pair, address account) external {
        SwapPair pair = SwapPair(_pair);
        pair.sync(account);
    }
}