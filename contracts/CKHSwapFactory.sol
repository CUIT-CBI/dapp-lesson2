// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./CKHSwapPair.sol";
contract CKHSwapFactory{
     mapping(address => mapping(address => address)) public SwapPairs;
     uint256 public PairCount;
     CKHSwapPair public PairLast;

     function createPairs(address token1,address token2) public {
        CKHSwapPair pair = new CKHSwapPair(token1,token2);
        require(SwapPairs[token1][token2]==address(0));
        SwapPairs[token1][token2]= address(pair);
        PairCount++;
        PairLast=pair;
    }
    
    function getPairLast() public view returns(CKHSwapPair){
        return (PairLast);
    }
}
