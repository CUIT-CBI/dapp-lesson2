// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./YHswapERC20.sol";
import "./YHrewardtoken.sol";
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
}

contract Staking{
    YHswapERC20 public swapLP;         //质押的
    YHrewardtoken public rewardtoken;   //“挖矿”得到的奖励代币
    uint256 public Duration; //质押时长
    mapping(address => uint256) public rewards;  //用户拥有的奖励数量
    mapping(address => uint256) private impawnBalances;  //用户已质押的LP数量
    uint256 private impawnTotalBalances; //质押总量
    uint256 public rewardPerToken;  //每token奖励数量
    uint256 public lastUpdateTime ;   //最近一次更新时间
    mapping(address => uint256) public userRewardPerToken; //用户每token奖励数量
    uint256 public timeFinish = 0;   //质押结束时间
    uint256 public rewardRate;//每区块奖励
    address public owner;

    constructor(address _rewardToken, address _swapLP,uint256 _Duration) public {
        rewardtoken = YHrewardtoken(_rewardToken);
        swapLP = YHswapERC20(_swapLP);
        Duration=_Duration;
        owner=msg.sender;
    }

     function update(address account) private{
        rewardPerToken = rewardsPerToken();
        lastUpdateTime = lastTimeReward();
        if (account != address(0)) {
            rewards[account] = Nowreward(account);
            userRewardPerToken[account] = rewardPerToken;
        }
      
    }

    //定奖励
     function RewardAmount(uint256 _allReward) external  {
         require(msg.sender==owner);
        update(address(0));
        rewardRate = _allReward/Duration;
        uint balance = rewardtoken.balanceOf(address(this));
        require(rewardRate <= balance/Duration, "reward too high");
        lastUpdateTime = block.timestamp;
        timeFinish = block.timestamp+Duration;
       
    }
      //更新时间
    function lastTimeReward()public returns(uint256){
         return Math.min(block.timestamp, timeFinish);
    }

     //获取每单位质押代币的奖励数量
    function rewardsPerToken() public  returns (uint256) {
        if (impawnTotalBalances == 0) {
            return rewardPerToken;
        }else{
           return rewardPerToken+(lastTimeReward()-lastUpdateTime)*rewardRate*1e18/impawnTotalBalances;
           }
       }

       //计算用户当前的挖矿奖励
    function Nowreward(address account) public  returns (uint256) {
        return impawnBalances[account]*(rewardsPerToken()-userRewardPerToken[account])/1e18+rewards[account];
    }

       //质押
     function stake(uint256 amount) external  {
        require(amount > 0, "Cannot stake 0");
        update(msg.sender);
        impawnTotalBalances = impawnTotalBalances + amount;
        impawnBalances[msg.sender] = impawnBalances[msg.sender]+amount;
        swapLP.transferFrom(msg.sender, address(this), amount);
        }

       //提取质押LP
    function withdraw(uint256 amount) public{
        update(msg.sender);
        require(amount > 0, "Cannot withdraw 0");
        impawnTotalBalances = impawnTotalBalances-amount;
        impawnBalances[msg.sender] = impawnBalances[msg.sender]-amount;
        swapLP.transfer(msg.sender, amount);
        }

        //提取奖励
    function Reward() public {
        update(msg.sender);
        if (rewards[msg.sender] > 0) {
            uint256 reward=rewards[msg.sender];
            rewards[msg.sender] = 0;
            rewardtoken.transfer(msg.sender, reward);
           
        }
    }

   
}