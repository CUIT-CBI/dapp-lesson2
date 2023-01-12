// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./YHswap.sol";
contract YHswapFactory{
     mapping(address => mapping(address => address)) public swapPairs;
     uint256 public pairCount;
     YHswap public PairLast;
    function createPairs(address token0,address token1)public {
                   
        YHswap pair = new YHswap(token0,token1);
        require(swapPairs[token0][token1]==address(0));
        swapPairs[token0][token1]= address(pair);
        pairCount++;
        PairLast=pair;
        
    }
    function getPairLast() public view returns(YHswap){
        return (PairLast);
    }
}
