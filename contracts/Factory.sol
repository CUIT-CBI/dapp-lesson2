// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ExchangeTwoTokens.sol";
contract Factory{
    FT public ft;
    constructor(FT _ft){
        ft=_ft;
    }

    mapping (address => mapping (address => address)) public Pair;
    address [] public allPairs;
    function createPair(address tokenZyh1, address tokenZyh2) external returns (address pair){
        require(tokenZyh1 != tokenZyh2, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenZyh1 < tokenZyh2 ? (tokenZyh1, tokenZyh2) : (tokenZyh2, tokenZyh1);
        require(token0 != address(0), 'ZERO_ADDRESS');
        //获得字节码
        bytes memory bytecode = type(ExchangeTwoTokens).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0,token1));
        assembly {               
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        new ExchangeTwoTokens{
            salt : salt
        }(token0,token1,ft);
        Pair[token0][token1] = pair;
        Pair[token1][token0] = pair;
        allPairs.push(pair);
    }
    function ifPairExist(address tokenZyh1,address tokenZyh2) external view   returns(bool) {
        return Pair[tokenZyh1][tokenZyh2] != address(0);
    }

    function getPair(address tokenZyh1,address tokenZyh2) view external  returns (address) {
        return Pair[tokenZyh1][tokenZyh2];
    }



}