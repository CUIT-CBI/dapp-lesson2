pragma solidity ^0.8.0;

import "./FT.sol";

contract Factory {

    mapping(address => mapping(address => address)) public getPairs;
    
    //创建交易对
    function createPair(address token0,address token1) public returns(address pair){
        require(getPairs[token0][token1] == address(0),'Invald_token0');
        getPairs[token0][token1] = pair;
        getPairs[token1][token0] = pair;
        return pair;
    }
}
