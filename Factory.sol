// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./exchange.sol";
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
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
      
        bytes memory bytecode = type(exchange).creationCode;
        bytes32 qq = keccak256(abi.encodePacked(token0,token1));
        assembly {               
        
            pair := create2(0, add(bytecode, 32), mload(bytecode), qq)
        }
        new exchange{
            qq : qq
        }(token0,token1,ft);
        Pair[token0][token1] = pair;
        Pair[token1][token0] = pair;
        allPairs.push(pair);
    }
    function exist(address tokenA,address tokenB) external view   returns(bool) {
        return Pair[tokenA][tokenB] != address(0);
    }

    function getPair(address tokenA,address tokenB) view external  returns (address) {
        return Pair[tokenA][tokenB];
    }



}