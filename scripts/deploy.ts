import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

let deployer;
async function main() {
  [deployer] = await ethers.getSigners();
  //部署swap工厂合约
  const YHswapFactory = await ethers.getContractFactory("YHswapFactory");
  const yhswapfactory = await YHswapFactory.deploy();
  console.log(`YHswapFactory deployed to ${yhswapfactory.address}`);
 
  //部署两个token
  const TOKEN = await ethers.getContractFactory("FT");
  const token0 = await TOKEN.deploy("xiannv", "XN");
  await token0.deployed();
  console.log(`token0 deployed to ${token0.address}`);
  const token1 = await TOKEN.deploy("yanhan", "YH");
  await token1.deployed();
  console.log(`token1 deployed to ${token1.address}`);
 
  //创建代币对
 await yhswapfactory.createPairs(token0.address,token1.address);
 const pair=await yhswapfactory.getPairLast();
  console.log(pair);
 
  //部署质押合约
  const YHswapERC20 = await ethers.getContractFactory("YHswapERC20");
  const yhswapERC20 = await YHswapERC20.deploy();
  console.log(yhswapERC20.address);
  const YHrewardtoken = await ethers.getContractFactory("YHrewardtoken");
  const yhrewardtoken = await YHrewardtoken.deploy("reward","RW");
  console.log(yhrewardtoken.address);
  const StakingFactory = await ethers.getContractFactory("StakingFactory");
  const stakingFactory = await StakingFactory.deploy(`${yhrewardtoken.address}`);
  console.log(stakingFactory.address);
  await yhrewardtoken.transfer(stakingFactory.address,1000);
   await stakingFactory.Create(yhswapERC20.address,1000,50,{gasLimit:1e6});
   }

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
