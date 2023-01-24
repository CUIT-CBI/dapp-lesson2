// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./mmzSwap.sol";
import "./FT.sol";

contract factory {

    mapping(address => mapping(address => address)) public pairs;

    function createPair(address token0, address token1) public returns(address){
        require(pairs[token0][token1] == address(0), "pair already exists !");
        LP pair = new LP(token0, token1);
        pairs[token0][token1] = address(pair);
        pairs[token1][token0] = address(pair);
        return address(pair);
    }

}