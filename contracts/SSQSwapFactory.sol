// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SSQSwapPair.sol";

contract SSQSwapFactory {
    mapping(address => mapping(address => address)) public pairs;

    function createPair(address token0, address token1) public returns (address) {
        SSQSwapPair pair = new SSQSwapPair(token0, token1);
        pairs[token0][token1] = address(pair);
        pairs[token1][token0] = address(pair);

        return address(pair);
    }

    function initializePair(address _pair, address account) external {
        SSQSwapPair pair = SSQSwapPair(_pair);
        pair.sync(account);
    }
}