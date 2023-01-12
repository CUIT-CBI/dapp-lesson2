// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./tokenPair.sol";

contract tokenFactory {
    FT public rewardToken = new FT("RewardToken", "RT");
    mapping(address => mapping(address => tokenPair)) public pairs;

    //创建交易对
    function creatPair(
        address token1,
        address token2,
        uint256 amount1In,
        uint256 amount2In
    ) public returns (address) {
        require(
            FT(token1).transferFrom(msg.sender, address(this), amount1In) &&
                FT(token2).transferFrom(msg.sender, address(this), amount2In)
        );
        require(
            address(pairs[token1][token2]) == address(0),
            "pair has already exists"
        );
        tokenPair pair = new tokenPair(
            token1,
            token2,
            amount1In,
            amount2In,
            rewardToken
        );
        FT(token1).transfer(address(pair), amount1In);
        FT(token2).transfer(address(pair), amount2In);
        pairs[token1][token2] = pair;
        //赋予mint权限
        rewardToken.setPair(address(pair));
        return address(pair);
    }
}
