// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import"./SAddress.sol";
import"./RAddress.sol;"

 //R为每秒钟的发放收益，
 //l(t)是在t区块，某用户提供的流动性的总价值
 //L(t)是在t区块，所质押的流动性的总价值
 //用户收益：R*l*(t2-t1)/L(t1)
contract DHLstaking {
    using SafeMath for uint;
    address public SAddress;//LP合约
    address public RAddress;//奖励币合约

    address public admin;//管理员地址
    uint public rewardBase;//每经过一个区块每rewardBase个LP可以得到一个rewardtoken
    uint256 private totalLP; //质押总量
    uint256 public immutable startBlock; // 在构造函数中定义
    uint256 public immutable endBlock; // 在构造函数中定义
    mapping(address => uint256) private LPbalances;  //矿工质押的LP数量
    mapping(address => uint256) public checkPoint;// 每次质押或提取LP时，更新这个值
    mapping(address => uint256) public calculatedReward;// 已经计算的奖励金
    mapping(address => uint256) public claimedReward;// 已经提取的奖励金
    constructor(address _SAddress, address _RAddress，uint _rewardBase, uint _period) {
        require(address(_SAddress) != address(0) && address(_RAddress) != address(0), "Address can not be zero");
        require(_rewardBase>0,"reward must above zero");
        SAddress = _SAddress;
        RAddress = _RAddress;
        rewardBase=_rewardBase;
        startBlock=block.number;
        endBlock = block.number + _period + 1;
        admin = msg.sender;
    }
    modifier onlyValidTime() {
        require( block.number>=startBlock && block.number<=endBlock, "overdue" );
        _;
    }

    // 质押
    function stake(uint256 _amount) public onlyValidTime returns (bool) {
        require(_amount > 0, "stake amount below zero");
        DHLswap(SAddress).transferFrom(msg.sender,address(this),_amount);
        totalLP+=_amount;
        if(LPbalances[msg.sender] != 0 ){
        calculatedReward[msg.sender] = calculatedReward[msg.sender].add((block.number.sub(checkPoint[msg.sender].div(LPbalances[msg.sender]))).mul(LPbalances[msg.sender].div(rewardBase)));
        }
        LPbalances[msg.sender]=LPbalances[msg.sender].add(_amount);
        checkPoint[msg.sender] = LPbalances[msg.sender] .mul(block.number);  
        emit Deposit(msg.sender, _amount);
         return true;
    }

      // 查询奖励金
    function getPendingReward(address _account)
        public
        view
        returns (uint256 pendingReward)
    {
        if(LPbalances[msg.sender] != 0 ){
        if (block.number<=endBlock){
        pendingReward = ((calculatedReward[_account]).add((block.number.sub(checkPoint[msg.sender].div(LPbalances[msg.sender]))).mul(LPbalances[msg.sender].div(rewardBase)))).sub(claimedReward[_account]); // 此处编写业务逻辑
        }
        else pendingReward = ((calculatedReward[_account]).add((endBlock.sub(checkPoint[msg.sender].div(LPbalances[msg.sender]))).mul(LPbalances[msg.sender].div(rewardBase)))).sub(claimedReward[_account]);
        }
        else pendingReward=0;
    }

    // 领取奖励金
    function claimReward(address  _toAddress) public returns (bool) {
        uint256 pendingReward= getPendingReward(_toAddress);
        claimedReward[_toAddress] = claimedReward[_toAddress].add(pendingReward);
        DHLrewardtoken(RAddress).transferFrom(RAddress,_toAddress,pendingReward);
        emit Claim(msg.sender, _toAddress, pendingReward);
        return true;
    }

    // 提取一定数量的LP
    function withdraw(uint256 _amount) public returns (bool) {
        require(_amount > 0,"withdraw amount <= 0");
        address  _toAddress = msg.sender;
        require(_amount <= LPbalances[msg.sender],"balance is insufficient");
        claimReward(_toAddress);
       if(LPbalances[msg.sender] != 0 ){
           if (block.number<=endBlock) calculatedReward[msg.sender] = calculatedReward[msg.sender].add((block.number.sub(checkPoint[msg.sender].div(LPbalances[msg.sender]))).mul(LPbalances[msg.sender].div(rewardBase)));
           else  calculatedReward[msg.sender] = calculatedReward[msg.sender].add((endBlock.sub(checkPoint[msg.sender].div(LPbalances[msg.sender]))).mul(LPbalances[msg.sender].div(rewardBase)));
        }
        DHLswap(SAddress).transferFrom(SAddress,msg.sender,_amount);
        LPbalances[msg.sender]=LPbalances[msg.sender].sub(_amount);
        totalLP-=_amount;
        if (block.number<=endBlock){
        checkPoint[msg.sender] = LPbalances[msg.sender] .mul(block.number);}  
        else checkPoint[msg.sender] = LPbalances[msg.sender] .mul(endBlock);
        emit Withdraw(msg.sender, _amount);
        return true;
    } 
  

    // 获取当前区块高度
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }
}

}