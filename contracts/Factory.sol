// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.17;

// import "./FT.sol";
// import "./Exchange.sol";

// // 工厂合约用来部署配对合约
// // 通过 createPair() 函数来创建新的配对合约实例

// contract Factory{
//     mapping(address => mapping(address => address)) public swapPair;
//     //交易对个数
//     uint256 public count;

//     function createPair(address token0, address token1) public {
//         require(token0 != token1, "Incorrect address");
//         require(address(swapPair[token0][token1]) == address(0), "Already exists.");
        
//         Exchange pair = new Exchange(token0, token1);
//         swapPair[token0][token1] == address(pair);

//         count++;
//         return pair;
//     }
// }