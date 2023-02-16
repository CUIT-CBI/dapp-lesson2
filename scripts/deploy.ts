import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("TokenA", "TA");
  await tokenA.deployed();
  const addressA = tokenA.address;

  const tokenB = await FT.deploy("TokenB", "TB");
  await tokenB.deployed();
  const addressB = tokenB.address;

  const rewardToken = await FT.deploy("RewardToken", "RT");
  await rewardToken.deployed();
  const addressRT = rewardToken.address;

  const tokenExchange = await ethers.getContractFactory("TokenExchange");
  const te = await tokenExchange.deploy(addressA, addressB);
  await te.deployed();
  const addressTE = te.address;

  const stakingPool = await ethers.getContractFactory("StakingPool");
  const staking = await stakingPool.deploy(addressTE, addressRT);
  await staking.deployed();

  console.log("deployed finish");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
