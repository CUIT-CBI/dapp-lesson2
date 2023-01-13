// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ExchangeToken.sol';
import './ExchangeETH.sol';
contract Factory{
    mapping (address => mapping (address => address)) public Pair;
    address [] public allPairs;


   function createExchangeToken(address tokenA, address tokenB) external {
        require(tokenA != tokenB, 'invilid address');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
        require(Pair[token0][token1] == address(0), 'EXISTS');
        bytes memory bytecode = abi.encodePacked(type(ExchangeToken).creationCode,abi.encode(token0,token1));
        bytes32 _salt = keccak256(abi.encodePacked(token0, token1));
        new ExchangeToken{
            salt : _salt
        }(token0,token1);
        address pair = address(uint160(uint(
            keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(bytecode))))));
        Pair[token0][token1] = pair;
        Pair[token1][token0] = pair;
        allPairs.push(pair);
    }
       function createExchangeETH(address token) external {
        require(token != address(0), 'ZERO ADDRESS');
        require(Pair[token][address(0)] == address(0), 'EXISTS');
        bytes memory bytecode = abi.encodePacked(type(ExchangeETH).creationCode,abi.encode(token));
        bytes32 _salt = keccak256(abi.encodePacked(token));
        new ExchangeETH{
            salt : _salt
        }(token);
        address pair = address(uint160(uint(
            keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(bytecode))))));
        Pair[address(0)][token] = pair;
        Pair[token][address(0)] = pair;
        allPairs.push(pair);
    }

    function ifPairExist(address tokenA,address tokenB) external view   returns(bool) {
        return Pair[tokenA][tokenB] != address(0);
    }

    function getPair(address tokenA,address tokenB) view external  returns (address) {
        return Pair[tokenA][tokenB];
    }



}