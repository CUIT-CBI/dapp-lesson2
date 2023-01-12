import './Staking.sol';

contract StakingFactory is Ownable {
    address public rewardtoken;  //奖励代币
    address[] public swapLPs;     //质押代币数组
    struct swapLPsRewardsInfo {
        address swapLPRewards;
        uint rewardAmount;
    }
    mapping(address => swapLPsRewardsInfo) public swapLPsRewardsInfoByswapLPs; //质押代币和质押合约信息之间的映射
     
    constructor(address _rewardstoken) public {
           rewardtoken = _rewardstoken;
 
    }

       function Create(address _swapLP, uint _rewardAmount,uint256 _Duration) public {
        swapLPsRewardsInfo storage info = swapLPsRewardsInfoByswapLPs[_swapLP];
        require(info.swapLPRewards == address(0), 'already deployed');
        info.swapLPRewards = address(new Staking(rewardtoken,_swapLP,_Duration));
        info.rewardAmount = _rewardAmount;
        swapLPs.push(_swapLP);
        require(IERC20(rewardtoken).transfer(info.swapLPRewards, _rewardAmount),'transfer failed');
        Staking(info.swapLPRewards).RewardAmount(_rewardAmount);
    }

 
}