// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./FT.sol";
import "./tokenPair.sol";
// 工厂合约用来部署配对合约
// 通过 createPair() 函数来创建新的配对合约实例
contract tokenFactory {
    FT public rewardToken = new FT("RewardToken", "RT");
    mapping(address => mapping(address => tokenPair)) public pairs;

    //创建交易对
    function creatPair(address tokenA,address tokenB,uint256 amount1In,uint256 amount2In) public returns (address) {
        require(
            FT(tokenA).transferFrom(msg.sender, address(this), amount1In) && FT(tokenB).transferFrom(msg.sender, address(this), amount2In)
        );
    //验证交易对是否存在
        require(
            address(pairs[tokenA][tokenB]) == address(0),
            "pair has already exists"
        );
        tokenPair pair = new tokenPair(
            tokenA,
            tokenB,
            amount1In,
            amount2In,
            rewardToken
        );
        FT(tokenA).transfer(address(pair), amount1In);
        FT(tokenB).transfer(address(pair), amount2In);
        pairs[tokenA][tokenB] = pair;
        //赋予mint权限
        rewardToken.setPair(address(pair));
        return address(pair);
    }
}
