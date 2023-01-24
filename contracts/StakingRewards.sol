// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./rewardsToken.sol";
import "./stakingToken.sol";

//质押合约
contract staking{
    using SafeMath for uint256;

    uint256 public stakingFinishTime = block.timestamp + stakingTime;
    uint256 public stakingTime;
    uint256 public rewardRate = 50;
    uint256 private _totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public lastupdateRewardTime;
    rewardsToken public rewardTokens;
    stakingToken public stakingTokens;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public userRewardsPerToken;

    event Stake(address sender,uint256 amounts);
    event Withdraw(address recipient,uint256 amounts);
    event Rewards(address recipient,uint256 amounts);

    constructor(
        address _rewardTokens,
        address _stakingTokens,
        uint256 _stakingTime
        ){
        rewardTokens = rewardsToken(_rewardTokens);
        stakingTokens = stakingToken(_stakingTokens);
        stakingTime = _stakingTime;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // function balanceOf(address account) external view returns (uint256) {
    //     return _balances[account];
    // }

    function getLastTime() public view returns(uint256){
        return Math.min(block.timestamp, stakingFinishTime);
    }

    //一段时间内每份代币获取的奖励代币数量
    function rewardPerToken() public view returns(uint256 reward){
        if(_totalSupply == 0){
            reward = rewardPerTokenStored;
        }
        reward = rewardPerTokenStored.add(getLastTime().sub(lastupdateRewardTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    //计算用户获得的总奖励
    function earned(address account) public view returns(uint256){
        return balances[account].mul(rewardPerToken().sub(userRewardsPerToken[account])).div(1e18).add(rewards[account]);
    }

    //质押代币
    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0);
        _totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        stakingTokens.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender, amount);
    }

    //提取质押代币
    function withdraw(uint256 amount) public updateReward(msg.sender) {
         require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        stakingTokens.transferFrom(address(this),msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    //领取挖矿奖励
    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0);
        rewards[msg.sender] = 0;
        rewardTokens.transfer(msg.sender, reward);

        emit Rewards(msg.sender, reward);
    }

    //解除质押
    function exitStake() public{
        withdraw(balances[msg.sender]);
        getReward();
    }

     //修饰函数
    modifier updateReward(address owner) {
        lastupdateRewardTime = getLastTime();
        rewardPerTokenStored = rewardPerToken();
        if(owner != address(0)){
            userRewardsPerToken[owner] = rewardPerTokenStored;
            rewards[owner] = earned(owner);
        }
        _;
    }
}