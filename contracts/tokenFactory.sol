// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./tokenPair.sol";

contract tokenFactory {
    // 存储币对
    mapping(address => mapping(address => address)) public getPair;

    // 创建币对
    function createPair(address tokenA,address tokenB,address setter)public returns(address){
        require(tokenA != tokenB,"createErr: A == B");
        require(getPair[tokenA][tokenB]==address(0),"createErr: pair is already exists");
        tokenPair pair = new tokenPair(tokenA,tokenB,setter);
        getPair[tokenA][tokenB] = address(pair);
        return address(pair);
    }
}