// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingRewards.sol";

//质押代币的合约工厂
contract StakingFactory is Ownable{
    address public rewardtokens;
    address[] public stakingTokens; 
    uint public stakingFirstTime;

    struct StakingRewardsInfo{
        address staking;
        uint rewardAmount;
    }

    mapping (address => StakingRewardsInfo) StakingRewardsInfoByStakingToken;

    constructor (
        address _rewardTokens
        ,uint _stakingFirstTime
        ) {
        rewardtokens = _rewardTokens;
        stakingFirstTime = _stakingFirstTime;
    }

    //部署staking合约
    function deploy(address stakingToken,uint _rewardAmount,uint stakingTime) public onlyOwner{
        StakingRewardsInfo storage info = StakingRewardsInfoByStakingToken[stakingToken];
        require(info.staking == address(0));
        info.staking = address(new staking(rewardtokens,stakingToken,stakingTime));
        info.rewardAmount = _rewardAmount;
        stakingTokens.push(stakingToken);
    }
}
