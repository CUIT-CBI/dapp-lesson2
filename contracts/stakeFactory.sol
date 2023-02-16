// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./staking.sol";

//质押代币的合约工厂，用来部署合约
contract stakingFactory is Ownable{
    //用来奖励的代币(一般是uniswap的平台币)
    address public rewardtokens;
    //用户用来质押的代币(一般是LP)
    address[] public stakingTokens; 
    //质押开始时间
    uint public stakingFirstTime;

    struct stakingInfo{
        address staking;//质押合约的地址=>每次部署的质押代币对应的质押合约地址是不一样的
        uint rewardAmount;//质押挖矿获得的奖励
    }
    //质押代币和质押合约信息
    mapping (address => stakingInfo) stakingInfoByStakingToken;

    constructor (address _rewardTokens,uint _stakingFirstTime){
        rewardtokens = _rewardTokens;
        stakingFirstTime = _stakingFirstTime;
    }

    //部署staking合约-传入的参数分别为：质押代币的地址，奖励代币数量，质押时长
    function deployStaking(address stakingToken,uint _rewardAmount,uint stakingTime) public onlyOwner{
        //得到质押合约信息
        stakingInfo storage info = stakingInfoByStakingToken[stakingToken];
        require(info.staking == address(0));//如果质押合约地址不为0.则说明已经部署过
        //创建staking合约,并保存合约地址
        info.staking = address(new Staking(rewardtokens,stakingToken,stakingTime));
        //保存质押挖矿获得的奖励代币
        info.rewardAmount = _rewardAmount;
        stakingTokens.push(stakingToken);
        require(block.timestamp > stakingFirstTime);
        //将用来奖励的代币传入质押合约中
        IERC20(rewardtokens).transfer(info.staking,_rewardAmount);
    }
}
