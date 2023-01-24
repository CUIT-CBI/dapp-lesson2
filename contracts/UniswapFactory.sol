// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UniswapPair.sol";

contract UniswapFactory {

    mapping(address => mapping(address => address)) public pairs;

    function createPair(address tokenA, address tokenB) public returns (address) {
        UniswapPair pair = new UniswapPair(tokenA, tokenB);
        pairs[tokenA][tokenB] = address(pair);
        pairs[tokenA][tokenB] = address(pair);

        return address(pair);
    }

    function initializePair(address _pair, address account) external {
        UniswapPair pair = UniswapPair(_pair);
        pair.sync(account);
    }
}
