// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./CoinPair.sol";

contract coinFactory {
    FT public rewardToken = new FT("RewardToken", "RT");
    mapping(address => mapping(address => tokenPair)) public pairs;

    function creatTransaction(
        address coinA,
        address coinB,
        uint256 amount1In,
        uint256 amount2In,
    ) public returns (address) {
        require(
            FT(coinA).transferFrom(msg.sender, address(this), amount1In) && FT(coinB).transferFrom(msg.sender, address(this), amount2In)
        );
        require(
            address(pairs[coinA][coinB]) == address(0),
            "pair has already exists"
        );
        tokenPair pair = new tokenPair(
            coinA,
            coinB,
            amount1In,
            amount2In,
            rewardToken
        );
        
        FT(coinA).transfer(address(pair), amount1In);
        FT(coinB).transfer(address(pair), amount2In);
        pairs[coinA][coinB] = pair;
        rewardToken.setPair(address(pair));
        return address(pair);
    }
}
