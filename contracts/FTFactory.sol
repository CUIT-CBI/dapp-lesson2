// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "./FTSwap.sol";

contract MyFactory {
    // 交易对
    mapping (address => mapping (address => address)) public swapPair;

    function createPairs(address tokenA, address tokenB) public returns(address){
            
            require(swapPair[tokenA][tokenB] == address(0), "swapPair is exist");
            FTSwap pair = new FTSwap(tokenA,tokenB);
            swapPair[tokenA][tokenB]= address(pair); 

            return swapPair[tokenA][tokenB];
    }
}