// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
//2020131141王小萌
import "./Lpair.sol";

contract factory {
    mapping(address => mapping(address => address)) public pair;
    address  [] public allpairs;
    address public WETH;
    

    constructor(address _WETH){
        WETH = _WETH;
    }
    function createPair(address token0,address token1)public returns(address lpair){
        require(token0 != address(0) && token1 !=address(0),"must");
    
        (address tokenA,address tokenB) = token0 < token1 ? (token0,token1) : (token1,token0);

        require(pair[tokenA][tokenB] == address(0),"exit pair");

       
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        lpair = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Lpair).creationCode)
            )))));
        pair[tokenA][tokenB] = lpair;
        pair[tokenB][tokenA] = lpair;
        allpairs.push(lpair);

        return lpair;
    }
    function getallpairLength()external view returns(uint256){
        return allpairs.length;
    }
    function exitPair(address token0,address token1)public view returns(bool){
        return (pair[token0][token1]== address(0));
    }


}