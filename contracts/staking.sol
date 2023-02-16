// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./rewardTokens.sol";
import "./LPToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//实现质押合约的主要方法
contract Staking{
    using SafeMath  for uint;

    rewardTokens public rewardUNITokens;//奖励代币，一般是UNI
    LPToken public stakingLPTokens;//质押代币，一般是LPtoken
    uint public stakingFinishTime = block.timestamp + stakingTime;//质押挖矿结束时间
    uint public stakingTime;//质押时间
    uint public rewardRate = 100;//挖矿速率
    uint private _totalSupply;//总的质押量
    uint public rewardPerTokenStored;//存储每单位token奖励代币
    uint public lastUpdateTime;

    //用户的奖励数量
    mapping(address => uint) public rewards;
    //用户的质押数量
    mapping(address => uint) public balances;
    //用户每token奖励数量
    mapping(address => uint) public userRewardsPerToken;

    event Stake(address sender,uint amounts);
    event Withdraw(address recipient,uint amounts);
    event Rewards(address recipient,uint amounts);

    constructor(address _rewardUNITokens,address _stakingLPTokens,uint _stakingTime){
        rewardUNITokens = rewardTokens(_rewardUNITokens);
        stakingLPTokens = LPToken(_stakingLPTokens);
        stakingTime = _stakingTime;
    }

    //修饰函数---用来更新一些变量
    modifier update(address owner) {
        //获取上一次更新时间
        lastUpdateTime = getLastTime();
        //用户操作之前得到每token奖励代币数量
        rewardPerTokenStored = rewardUNIPerToken();
        if(owner != address(0)){
            userRewardsPerToken[owner] = rewardPerTokenStored;
            rewards[owner] = allRewardsOfUser(owner);
        }
        _;
    }

    // 获取上一次更新的时间
    function getLastTime() public view returns(uint){
        return Math.min(block.timestamp, stakingFinishTime);
    }

    //一段时间内每份LP获取的奖励代币数量
    function rewardUNIPerToken() public view returns(uint rewardUNI){
        if(_totalSupply == 0){
            rewardUNI = rewardPerTokenStored;
        }
        rewardUNI = rewardPerTokenStored.add(getLastTime().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    //计算用户获得的总奖励
    function allRewardsOfUser(address account) public view returns(uint){
        return balances[account].mul(rewardUNIPerToken().sub(userRewardsPerToken[account])).div(1e18).add(rewards[account]);
    }

    //质押代币
    function stake(uint stakingAmounts) public update(msg.sender) {
        require(stakingAmounts > 0);
        //更新总的质押量
        _totalSupply = _totalSupply.add(stakingAmounts);
        //更新用户的质押数量
        balances[msg.sender] = balances[msg.sender].add(stakingAmounts);
        //将质押的代币传入到质押合约中
        stakingLPTokens.transferFrom(msg.sender, address(this), stakingAmounts);
        emit Stake(msg.sender, stakingAmounts);
    }

    //提取质押的代币
    function withdraw(uint stakingAmounts) public update(msg.sender) {
        require(stakingAmounts > 0);
        _totalSupply = _totalSupply.sub(stakingAmounts);
        balances[msg.sender] = balances[msg.sender].sub(stakingAmounts);
        stakingLPTokens.transferFrom(address(this), msg.sender, stakingAmounts);
        emit Withdraw(msg.sender, stakingAmounts);
    }

    //用户领取挖矿奖励
    function getRewards() public update(msg.sender) {
        //得到奖励的数量
        uint stakingRewards = rewards[msg.sender];
        require(stakingRewards > 0);
        //将rewards清零
        rewards[msg.sender] = 0;
        //将奖励转发给用户
        rewardUNITokens.transfer(msg.sender, stakingRewards);

        emit Rewards(msg.sender, stakingRewards);
    }

    //解除质押
    function exitStake() public{
        //提取质押的所有LPToken
        withdraw(balances[msg.sender]);
        //获得相应的挖矿奖励
        getRewards();
    }
}