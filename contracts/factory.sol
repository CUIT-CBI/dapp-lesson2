// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "./swap.sol";

contract factory {
   
    mapping(address => mapping(address => address)) public getPair;

 
    function createPair(address tokenA,address tokenB,address setter)public returns(address pair){
        require(tokenA != tokenB,"A == B");
        require(getPair[tokenA][tokenB]==address(0),"pair is already exists");
        uniswap pair = new uniswap(tokenA,tokenB,setter);
        getPair[tokenA][tokenB] = address(pair);
    }
}
