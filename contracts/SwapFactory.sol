// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './SwapStore.sol';

contract SwapFactory  {
    //记录交易对地址的mapping
    mapping(address => mapping(address => address)) public getPair;

    //记录所有交易对地址的数组
    address[] public allPairs;

    //交易对被创建时触发的事件
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    //创建交易对
    function createPair(address token0, address token1) external returns (address pair) {
        require(token0 != token1, "address same !");
        require(token0 != address(0) && token1 != address(0), "address cant be 0");
        //要求交易对并未创建（不能重复创建相同的交易对）
        require(getPair[token0][token1] == address(0), "pair has existed"); 
        
        //创建合约对象
        bytes memory bytecode = type(SwapStore).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            //使用create2函数来创建新合约
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SwapStore(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; 
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }


}
