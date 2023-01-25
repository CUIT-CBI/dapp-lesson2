// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract uniswapdemo {

    mapping(address => uint256) public balanceOfA;//账户上的A余额
    mapping(address => uint256) public balanceOfB;//账户上的B余额
    mapping(address => uint256) public liquidityProviderA;//流动性提供商增加的A数量
    mapping(address => uint256) public liquidityProviderB;//流动性提供商增加的B数量
    uint256 public poolA;
    uint256 public poolB;
    uint256 public k;
    uint256 public poolPremiumOfA;//A手续费池
    uint256 public poolPremiumOfB;//B手续费池

    constructor(uint256 mountA, uint256 mountB){
        require(mountA > 0, "invalid value of tokenA!");
        require(mountB > 0, "invalid value of tokenB!");

        poolA = mountA;
        poolB = mountB;
         require(k>=(poolA*poolB),"k is too large,cant add liquidity  more");
        k = poolA * poolB;

        liquidityProviderA[msg.sender] = mountA;
        liquidityProviderB[msg.sender] = mountB;

    }

    function addLiquidity(uint256 mountA, uint256 mountB) public {//增加流动性
        require(mountA > 0, "invalid value of tokenA!");
        require(mountB > 0, "invalid value of tokenB!");
        poolA += mountA;
        poolB += mountB;
        require(k>=(poolA*poolB),"k is too large,cant add liquidity  more");
        k = poolA * poolB;

        liquidityProviderA[msg.sender] += mountA;
        liquidityProviderB[msg.sender] += mountB;
    }
 //后期再追加移除部分流动性而不是全部
    function removeLiquidity() public {//移除流动性
        require(liquidityProviderA[msg.sender] > 0, "you are not the liquidity-provider!");

        uint256 premiumA;
        uint256 premiumB;

        //待返还手续费计算 ,设计得有一点问题，最终获得流动性收益的值完全取决于调用removeLiquidity的时候的状态，可能会造成系统错误目前尚未解决。
        premiumA = poolPremiumOfA * (liquidityProviderA[msg.sender] / poolA);
        premiumB = poolPremiumOfB * (liquidityProviderB[msg.sender] / poolB);
        //更新手续费池
        poolPremiumOfA -= premiumA;
        poolPremiumOfB -= premiumB;
        //返还流动性以及手续费
        balanceOfA[msg.sender] += liquidityProviderA[msg.sender] + premiumA;
        balanceOfB[msg.sender] += liquidityProviderB[msg.sender] + premiumB;
        //更新交易池以及key值,考虑一下是否有接下来poolA或者poolB为负的情况
        poolA -= liquidityProviderA[msg.sender];
        poolB -= liquidityProviderB[msg.sender];
        k = poolA * poolB;
        //更新流动性提供商信息
        liquidityProviderA[msg.sender] = 0;
        liquidityProviderB[msg.sender] = 0;
        
    }

    function getAWithB(uint256 mountB) public {//使用B购买A
       //maybe is useless
        require(msg.sender != address(0), "invalid address!");
        require(mountB > 0, "invalid input!");
        require(k / (poolB + mountB) < poolA, "you can't trade all of the A");

        uint256 beTradedOfA;//待交易的A值

        beTradedOfA = poolA - k / (poolB + mountB); 

        poolA -= beTradedOfA;
        poolB += mountB;
        balanceOfA[msg.sender] += beTradedOfA * 997 / 1000;
        poolPremiumOfA += beTradedOfA * 3 / 1000;//收取千分之三手续费
    }

    function getBWithA(uint256 mountA) public {//使用A购买B
         //maybe is useless
         require(msg.sender != address(0), "invalid address!");
        require(mountA > 0, "invalid input!");
        require(k / (poolA + mountA) < poolB, "you can't trade all of the B");

        uint256 beTradedOfB;//待交易的B值

        beTradedOfB = poolB - k / (poolA + mountA); 

        poolB -= beTradedOfB;
        poolA += mountA;
        balanceOfB[msg.sender] += beTradedOfB * 997 / 1000;
        poolPremiumOfB += beTradedOfB * 3 / 1000;//收取千分之三手续费

    }

}