// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ExchangeTwoTokens.sol";
contract Factory{
    FT public ft;
    constructor(FT _ft){
        ft=_ft;
    }
    //交易对
    mapping (address => mapping (address => address)) public Pair;
    address [] public allPairs;
    function createPair(address tokenA, address tokenB) external returns (address pair){
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        // tA 和 tB 进行排序，确保tA小于tB。返回对应的t0和t1
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        //判断出tA不为0，则tB也不为0
        require(token0 != address(0), 'ZERO_ADDRESS');
        //获得合约编译后的字节码
        bytes memory bytecode = type(ExchangeTwoTokens).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0,token1));
        //使用内联汇编
        assembly {               
        //通过create2方法布署合约,并且加salt,返回地址到pair变量
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        new ExchangeTwoTokens{
            salt : salt
        }(token0,token1,ft);
        Pair[token0][token1] = pair;
        //反向映射填充
        Pair[token1][token0] = pair;
        allPairs.push(pair);
    }
    function ifPairExist(address tokenA,address tokenB) external view   returns(bool) {
        return Pair[tokenA][tokenB] != address(0);
    }

    function getPair(address tokenA,address tokenB) view external  returns (address) {
        return Pair[tokenA][tokenB];
    }



}