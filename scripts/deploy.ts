/*
这段代码使用 hardhat 和 ethers.js 库在 Ethereum 网络上部署了三个智能合约：
两个 ERC20 代币合约 "FT1" 和 "FT2"，以及一个交易池合约 "SwapPool"。
*/
import { ethers } from "hardhat";

async function main() {

   //首先，通过调用 ethers.getContractFactory("FT") 获取 ERC20 代币合约的工厂。
    //然后调用 FT1.deploy("token1", "t1") 和 FT2.deploy("token2", "t2") 分别部署两个 ERC20 代币合约，并将它们分别赋值给变量 ft1 和 ft2。 
  //部署第一种erc20代币
  const FT1 = await ethers.getContractFactory("FT");//
  const ft1 = await FT1.deploy("token1", "t1");
  //部署第二种erc20代币
  const FT2 = await ethers.getContractFactory("FT");
  const ft2 = await FT2.deploy("token2", "t2");



  //以上面两种代币作为币对部署交易池
  //接下来调用 ethers.getContractFactory("SwapPool") 获取交易池合约的工厂。
  const SwapPool = await ethers.getContractFactory("ChangeToken");
  //调用 SwapPool.deploy(ft1.address,ft2.address) 部署交易池合约，并将它赋值给变量 swappool，同时将ft1和ft2的地址传入。
  const swappool = await SwapPool.deploy(ft1.address,ft2.address);

  //等待部署
  await ft1.deployed();
  await ft2.deployed();
  await swappool.deployed();

  console.log(`FT1 deployed to ${ft1.address}`);
  console.log(`FT2 deployed to ${ft2.address}`);
  console.log(`SwapPool deployed to ${swappool.address}`);

}

// We recommend this pattern to be able to use async/await everywhere