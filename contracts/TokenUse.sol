// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./TokenCreat.sol";

contract TokenUse {
    // 币对存放
    mapping(address => mapping(address => address)) public getPair;

    // 币对创建
    function Tokencreat(
        address tokenA,
        address tokenB,
        address index
    ) public returns (address) {
        require(tokenA != tokenB, "Err: A == B");
        require(getPair[tokenA][tokenB] == address(0), "Err: token exists");
        TokenCreat pair = new TokenCreat(tokenA, tokenB, index);
        getPair[tokenA][tokenB] = address(pair);
        return address(pair);
    }
}
