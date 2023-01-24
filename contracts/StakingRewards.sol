//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Exchange.sol";
import "./RewardToken.sol";
/**
 * @dev implemented liquidity provider token(LP) mining, and the mathematic is from SuShiSwap
 */

contract StakingRewards {

    RewardToken public Liquidity; // Token to be payed as reward
    uint256 private rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant STAKER_SHARE_PRECISION = 1e12; // A big number to perform mul and div operations
    Exchange stakeToken; // token to be staked
    uint256 tokensStaked; // Total tokens staked
    address[] stakers; // Stakers in this pool
   
        
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 rewards; // The reward tokens quantity the user can harvest
        uint256 lastRewardedBlock; // Last block number the user had their rewards calculated
    }

    mapping(address => PoolStaker) poolStakers;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);

    constructor(address _rewardTokenAddress, uint256 _rewardTokensPerBlock) {
        Liquidity = RewardToken(_rewardTokenAddress);
        rewardTokensPerBlock = _rewardTokensPerBlock;
    }
    
    function addStakerToPoolIfInexistent(address depositingStaker) private {

        for (uint256 i; i < stakers.length; i++) {
            address existingStaker = stakers[i];
            if (existingStaker == depositingStaker) return;
        }
        stakers.push(msg.sender);
    }

    /**
     * @dev Deposit tokens to an existing pool
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Deposit amount can't be zero");
        
        PoolStaker storage staker = poolStakers[msg.sender];

        // Update pool stakers
        updateStakersRewards();
        addStakerToPoolIfInexistent(msg.sender);

        // Update current staker
        staker.amount = staker.amount + _amount;
        staker.lastRewardedBlock = block.number;

        // Update pool
        tokensStaked = tokensStaked + _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _amount);
        stakeToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    /**
     * @dev Withdraw all tokens from an existing pool
     */
    function withdraw() external {
        PoolStaker storage staker = poolStakers[msg.sender];
        uint256 amount = staker.amount;
        require(amount > 0, "Withdraw amount can't be zero");

        // Update pool stakers
        updateStakersRewards();

        // Pay rewards
        harvestRewards();

        // Update staker
        staker.amount = 0;

        // Update pool
        tokensStaked = tokensStaked - amount;

        // Withdraw tokens
        emit Withdraw(msg.sender, amount);
        stakeToken.transfer(
            address(msg.sender),
            amount
        );
    }

    /**
     * @dev Harvest user rewards from a given pool id
     */
    function harvestRewards() public {
        updateStakersRewards();
        PoolStaker storage staker = poolStakers[msg.sender];
        uint256 rewardsToHarvest = staker.rewards;
        staker.rewards = 0;
        emit HarvestRewards(msg.sender, rewardsToHarvest);
        Liquidity.mint(msg.sender, rewardsToHarvest);
    }

    /**
     * @dev Loops over all stakers from a pool, updating their accumulated rewards according
     * to their participation in the pool.
     */
    function updateStakersRewards() private {
        for (uint256 i; i < stakers.length; i++) {
            address stakerAddress = stakers[i];
            PoolStaker storage staker = poolStakers[stakerAddress];
            if (staker.amount == 0) return;
            uint256 stakedAmount = staker.amount;
            uint256 stakerShare = (stakedAmount * STAKER_SHARE_PRECISION / tokensStaked);
            uint256 blocksSinceLastReward = block.number - staker.lastRewardedBlock;
            uint256 rewards = (blocksSinceLastReward * rewardTokensPerBlock * stakerShare) / STAKER_SHARE_PRECISION;
            staker.lastRewardedBlock = block.number;
            staker.rewards = staker.rewards + rewards;
        }
    }
}