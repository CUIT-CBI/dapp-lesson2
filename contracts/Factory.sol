// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./myexchange.sol";

contract myFactory{
    FT public ft;
    constructor(FT _ft){
        ft=_ft;
    }
    //交易对
    mapping (address => mapping (address => address)) public Pair;
    address [] public allPairs;
    function createPair(address tokenD, address tokenN) external returns (address pair){
        require(tokenD != tokenN, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenD < tokenN ? (tokenD, tokenN) : (tokenN, tokenD);
        require(token0 != address(0), 'ZERO_ADDRESS');
        //获得合约编译后的字节码
        bytes memory bytecode = type(exchange).creationCode;
        bytes32 aa = keccak256(abi.encodePacked(token0,token1));
        assembly {               
        //create2方法布署合约,加aa,返回地址到pair变量
            pair := create2(0, add(bytecode, 32), mload(bytecode), aa)
        }
        new exchange{
            aa : aa
        }(token0,token1,ft);
        Pair[token0][token1] = pair;
        Pair[token1][token0] = pair;
        allPairs.push(pair);
    }
    function exist(address tokenD,address tokenN) external view   returns(bool) {
        return Pair[tokenD][tokenN] != address(0);
    }

    function getPair(address tokenD,address tokenN) view external  returns (address) {
        return Pair[tokenD][tokenN];
    }
