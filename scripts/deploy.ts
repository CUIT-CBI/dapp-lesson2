import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
async function main() {
  //部署工厂合约
  const  MyFactory = await ethers.getContractFactory("FTFactory");
  const factory = await MyFactory.deploy();
  await factory.deployed();
  console.log(`factory address:${factory.address}`);
  
  //部署A B token
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("tokenA", "ZYN_A");
  await tokenA.deployed();
  
  const tokenB = await FT.deploy("tokenB", "ZYN_B");
  await tokenB.deployed();
  console.log(`tokenA deployed to ${tokenA.address}`);
  console.log(`tokenB deployed to ${tokenB.address}`);
  
  //创建token对
  const pair = await factory.createPairs(tokenA.address,tokenB.address);
  console.log(`pair deployed to ${pair.address}`);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
