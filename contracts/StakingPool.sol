// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingPool {
    using SafeMath for uint;

    ERC20 public stakingToken;
    ERC20 public rewardToken;
    uint public rate;
    uint public endTime;
    uint public totalReward;
    uint public lastUpdateTime;
    address public admin;

    mapping(address => uint) private TotalRewardBeforeStake;
    mapping(address => uint) private Reward;
    mapping(address => uint) private Balance;

    event StakingToken(address owner, uint amount);
    event Withdraw(address owner, address to, uint amount);
    event GetReward(address owner, address to, uint amount);
    event UpdateRate(uint reward, uint duration);

    constructor(ERC20 _stakingToken, ERC20 _rewardToken) {
        require(address(_stakingToken) != address(0) && address(_rewardToken) != address(0), "Address can not be zero");
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        admin = msg.sender;
    }

    modifier updateReward(address _owner) {
        lastUpdateTime = _compareTimestamp();
        Reward[msg.sender] = _calculatedReward();
        if(_owner != address(0)){
            totalReward = _calculatedRewardBefore();
            TotalRewardBeforeStake[_owner] = totalReward;
        }       
        _;
    }

    function updateRate(uint _reward, uint _duration) external updateReward(address(0)) {
        require(msg.sender == admin, "You are not admin");
        if (block.timestamp > endTime){
            rate = _reward.div(_duration);       
        } else {
            uint _leftover =endTime.sub(block.timestamp).mul(rate);
            rate = _leftover.add(_reward).div(_duration);
        }
        require(rewardToken.balanceOf(address(this)) >= rate.mul(_duration), "RewardToken is not enough");
        endTime = block.timestamp.add(_duration);
        lastUpdateTime = block.timestamp;
        emit UpdateRate(_reward, _duration); 
    }

    function stakToken(uint _amount) public updateReward(msg.sender) {
        require(_amount > 0, "The amount must  over zero");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        Balance[msg.sender] = Balance[msg.sender].add(_amount);
        emit StakingToken(msg.sender, _amount);
    }

    function withdraw(address _to) public updateReward(msg.sender) {
        getReward(_to);
        uint _amount = Balance[msg.sender];
        delete Balance[msg.sender];
        stakingToken.transfer(_to, _amount);
        emit Withdraw(msg.sender, _to, _amount);
    }

    function getReward(address _to) public updateReward(msg.sender) {
        uint _amount = Reward[msg.sender];
        if (_amount > 0) {
            delete Reward[msg.sender];
            rewardToken.transfer(_to, _amount);
            emit GetReward(msg.sender, _to, _amount);
        }       
    }

    function _totalSupply() private view returns(uint) {
        return stakingToken.balanceOf(address(this));
    }

    function _calculatedRewardBefore() private view returns(uint){
        uint _total = _totalSupply();
        return totalReward.add(
                _compareTimestamp().sub(lastUpdateTime).mul(rate).mul(10**18).div(_total)
            );
    }

    function _calculatedReward() private view returns(uint) {
        return Balance[msg.sender].mul(_calculatedRewardBefore().sub(TotalRewardBeforeStake[msg.sender])).div(10**18).add(Reward[msg.sender]);
    }

    function _compareTimestamp() private view returns(uint) {
        return Math.min(block.timestamp, endTime);
    }

}