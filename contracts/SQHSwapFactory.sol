// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./SQHSwapPair.sol";
contract SQHSwapFactory{
     mapping(address => mapping(address => address)) public SwapPairs;
     uint256 public PairCount;
     SQHSwapPair public PairLast;

     function createPairs(address token1,address token2) public {
        SQHSwapPair pair = new SQHSwapPair(token1,token2);
        require(SwapPairs[token1][token2]==address(0));
        SwapPairs[token1][token2]= address(pair);
        PairCount++;
        PairLast=pair;
    }

    function getPairLast() public view returns(SQHSwapPair){
        return (PairLast);
    }
}
