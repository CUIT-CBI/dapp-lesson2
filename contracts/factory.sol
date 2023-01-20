// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./tokenExchange.sol";
contract Factory{
    mapping (address => mapping (address => address)) public getPair;
    address [] public Pairs;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);


   function createExchangeToken(address tokenA, address tokenB) external {
       require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
    // 对tokenA和tokenB进行大小排序,确保tokenA小于tokenB
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    // 确认token0不等于0地址
        require(token0 != address(0), 'ZERO_ADDRESS');
    //确认mapping不存在
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); 
    //创建tokenExchange编译后的字节码变量
       bytes memory bytecode = type(tokenExchange).creationCode;
        bytes32 _salt = keccak256(abi.encodePacked(token0, token1));
    //创建实例传入token0和token1
        new tokenExchange{
            salt : _salt
        }(token0,token1);
        address pair = address(uint160(uint(
        keccak256(abi.encodePacked(bytes1(0xff),address(this),_salt,keccak256(bytecode))))));

    //创建映射
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        Pairs.push(pair);
        emit PairCreated(token0, token1, pair, Pairs.length);
    }
}