import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
//部署ERC20币A合约
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("TokenA", "A");
  await tokenA.deployed();
  const addressA = tokenA.address;
//部署ERC20币B合约
  const tokenB = await FT.deploy("TokenB", "B");
  await tokenB.deployed();
  const addressB = tokenB.address;
//部署DHLswap合约
  const DHLswap = await ethers.getContractFactory("DHLswap");
  const swap = await DHLswap.deploy(addressA, addressB);
  await swap.deployed();
  const swapAddress = swap.address;
//部署DHLrewardtoken合约
  const DHLrewardtoken = await ethers.getContractFactory("DHLrewardtoken");
  const rewardToken = await DHLrewardtoken.deploy();
  await rewardToken.deployed();
  const rewardAddress = rewardToken.address;
//部署DHLstaking合约
  const DHLstaking = await ethers.getContractFactory("DHLstaking");
  const staking = await DHLstaking.deploy(swapAddress, rewardAddress);
  await staking.deployed();

  console.log("contracts deployment finished");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
