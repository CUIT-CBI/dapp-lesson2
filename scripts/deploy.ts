import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  //部署工厂合约
  const  MyFactory = await ethers.getContractFactory("MyFactory");
  const factory = await MyFactory.deploy();
  await factory.deployed();
  console.log(`factory address:${factory.address}`);

  //部署A B token
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("tokenA", "ZSLA");
  await tokenA.deployed();
  const tokenB = await FT.deploy("tokenB", "ZSLB");
  await tokenB.deployed();
  console.log(`tokenA deployed to ${tokenA.address}`);
  console.log(`tokenB deployed to ${tokenB.address}`);
  
  //创建token对
  const pair = await factory.createPairs(tokenA.address,tokenB.address);
  console.log(`pair deployed to ${pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
