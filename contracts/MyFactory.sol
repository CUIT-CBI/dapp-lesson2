// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./ZhouSwap.sol";

contract MyFactory {

    mapping (address => mapping (address => address)) public swapPair;

    function createPairs(address tokenA, address tokenB) public returns(address){
            
            require(swapPair[tokenA][tokenB] == address(0), "swapPair is exist");
            ZhouSwap pair = new ZhouSwap(tokenA,tokenB);
            swapPair[tokenA][tokenB]= address(pair); 

            return swapPair[tokenA][tokenB];
    }
}