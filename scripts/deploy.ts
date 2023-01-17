// 部署脚本
import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  let deployer = await ethers.getSigners();
  const provider = await ethers.providers.getDefaultProvider();

  // 部署FT合约
  const ERC20_FT = await ethers.getContractFactory("FT");
  const FT = await ERC20_FT.deploy("Zhang YQ", "ZYQ");
  await FT.deployed();
  console.log(`FT deployed to ${FT.address}`);
 
  // 部署Factory合约
  const ZYQFactory = await ethers.getContractFactory("ZYQFactory");
  const Factory = await ZYQFactory.deploy();
  await Factory.deployed();
  console.log(`Factory deployed to ${Factory.address}`);

  // 部署Pair合约
  const ZYQPair = await ethers.getContractFactory("ZYQPair");
  const Pair = await ZYQPair.deploy();
  await Pair.deployed();
  console.log(`Pair deployed to ${Pair.address}`);

  // 部署LPtoken合约
  const ZYQLPToken = await ethers.getContractFactory("ZYQLPToken");
  const LPToken = await ZYQLPToken.deploy();
  await LPToken.deployed();
  console.log(`LPToken deployed to ${LPToken.address}`);

  // 部署StakingRewards合约
  const ZYQStakingRewards = await ethers.getContractFactory("ZYQStakingRewards");
  const StakingRewards = await ZYQStakingRewards.deploy();
  await StakingRewards.deployed();
  console.log(`StakingRewards deployed to ${StakingRewards.address}`);
}