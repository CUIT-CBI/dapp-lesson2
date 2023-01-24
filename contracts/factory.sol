// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./swap.sol";

contract factory {
   
    //存放转换的两种代币存放的地址
    mapping(address => mapping(address => address)) public getPair;

    function createPair(address tokenA,address tokenB,address setter)public returns(address pair){
        //两个地址不能够相同
        require(tokenA != tokenB,"A == B");
        //必须是uniswap中未创建过的pair
        require(getPair[tokenA][tokenB]==address(0),"pair is already exists");
        uniswap pair = new uniswap(tokenA,tokenB,setter);
        getPair[tokenA][tokenB] = address(pair);
    }
}
