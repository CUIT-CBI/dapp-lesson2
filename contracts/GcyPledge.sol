// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./GcyERC20.sol";//质押的币pledgedToken
import "./FT.sol";//奖励的币rewardToken

/*
构思：
1.本实验实现单币质押挖矿
2.无活动期，没有结束时间默认永续，意味着可随时质押、随时解押提取本金和收益，与活期存款类似
3.不限制用户的最大挖矿额度即最大收益分配额度。质押数量越多，质押时间越久，收益越多
4.质押的币和挖矿奖励的币均是ERC20代币
5.根据质押量按照比例分配产出的新币：用户收益=用户质押数量/总质押数量*每小时产出的新币*用户质押时间(以小时为单位)
6.通过增加时间(以小时为单位)模拟挖矿，假设每小时稳定产出10个币
*/
contract GcyPledge is FT {
    GcyERC20 pledgedToken;//质押币
    //权益发放者地址，也是挖矿产出币的接收地址，设置为Remix提供的最后一个地址
    address public profitor = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    uint public time;//质押平台运行时间，假设从0开始
    uint minPledgeAmount = 10000000000000000000;//单次最少质押额度
    uint public totalPledgeAmount;//总质押数量
    uint public outAmountPerHour = 10000000000000000000;//假设每小时稳定产出10个币，精度18
    uint public totalOutAmount;//产出token总数
    
    mapping(address => uint) public pledgeAmount;//用户质押数量
    mapping(address => uint) public pledgeTimeStart;//用户开始质押的时间

    event PledgeToken(address indexed operator, uint amount);
    event WithdrawToken(address indexed operator, uint amount);
    event WithdrawProfit(address indexed operator, uint amount);

    constructor(GcyERC20 _pledgedToken) FT("rewardToken","CBI") {
        pledgedToken = _pledgedToken;
    }

    //获取平台运行时间
    function getTime() public view returns (uint _time) {
        _time = time;
    }

    //通过增加时间(以小时为单位)模拟挖矿，假设每小时稳定产出10个币
    function minerByAddHours(uint hour) public onlyOwner returns (bool) {
        time += hour;//更新平台时间
        uint outAmount = hour * outAmountPerHour;//产出币的数目，假设每小时稳定产出10个币，精度18
        super._mint(profitor, outAmount);//挖矿产出
        totalOutAmount += outAmount;//更新总产出
        return true;
    }

    //质押代币
    function pledgeToken(uint amount) public returns (bool) {
        require(amount >= minPledgeAmount, 'invalid amount');
        //本实验涉及授权转账均采用手动授权
        pledgedToken.transferFrom(msg.sender, address(this), amount);
        pledgeTimeStart[msg.sender] = getTime();//记录用户质押开始时间
        pledgeAmount[msg.sender] += amount;//更新用户质押数量
        totalPledgeAmount += amount;//更新总质押数量
        emit PledgeToken(msg.sender, amount);
        return true;
    }

    //查询用户质押时间
    function getPledgeTime() public view returns (uint _pledgeTime) {
        require(pledgeAmount[msg.sender] > 0, 'no pledgeToken');//无质押无质押时间
        _pledgeTime = getTime() - pledgeTimeStart[msg.sender];//计算用户目前为止的质押时间
    }

    //查询收益
    function getProfit() public view returns (uint profit) {
        require(pledgeAmount[msg.sender] > 0, 'no pledgeToken');//无质押无收益
        uint pledgeTime = getPledgeTime();//计算用户目前为止的质押时间
        //用户收益=用户质押数量/总质押数量*每小时产出的新币*用户质押时间(以小时为单位)
        profit = pledgeAmount[msg.sender] * outAmountPerHour * pledgeTime / totalPledgeAmount;
    }

    //提取收益
    function withdrawProfit() public returns (bool) {
        uint profit = getProfit();
        transferFrom(profitor, msg.sender, profit);//收益由权益发放者发放，发放的是rewardToken CBI
        //提取收益后更新质押开始时间，因为到当前这个时间的收益已经提取，此后重新累计
        pledgeTimeStart[msg.sender] = getTime();
        emit WithdrawProfit(msg.sender, profit);
        return true;
    }

    //提取本金
    function withdrawToken(uint amount) public returns (bool) {
        //确保用户在提取本金的时候提取该部分本金的收益，因为无论是否提取所有本金，收益是重新计算的，前后收益会不一致
        if (getProfit() != 0) {
            withdrawProfit();
        }
        require(amount <= pledgeAmount[msg.sender], 'invalid amount');
        pledgedToken.transfer(msg.sender, amount);//本金返回原账户
        pledgeAmount[msg.sender] -= amount;//更新用户质押数量
        totalPledgeAmount -= amount;//更新总质押数量
        emit WithdrawToken(msg.sender, amount);
        return true;
    }
}