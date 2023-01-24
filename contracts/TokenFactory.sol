// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./TokenPair.sol";

contract TokenFactory {
    FT public rewardToken = new FT("RewardToken", "RT");
    //存储币对
    mapping(address => mapping(address => tokenPair)) public pairs;

    //创建交易对
    function creatPair(
        address tokenA,
        address tokenB,
        uint256 amountAIn,
        uint256 amountBIn
    ) public returns (address) {
        require(
            FT(tokenA).transferFrom(msg.sender, address(this), amountAIn) &&
                FT(tokenB).transferFrom(msg.sender, address(this), amountBIn)
        );
        require(
            address(pairs[tokenA][tokenB]) == address(0),
            "pair has already exists"
        );
        tokenPair pair = new tokenPair(
            tokenA,
            tokenA,
            amountAIn,
            amountBIn,
            rewardToken
        );
        FT(tokenA).transfer(address(pair), amountAIn);
        FT(tokenB).transfer(address(pair), amountBIn);
        pairs[tokenA][tokenB] = pair;
        //赋予mint权限
        rewardToken.setPair(address(pair));
        return address(pair);
    }
}