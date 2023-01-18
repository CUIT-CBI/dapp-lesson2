import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const token0 = await FT.deploy("token0", "ZSY");
  await token0.deployed();
  const token1 = await FT.deploy("token2", "ZSY");
  await token1.deployed();
  console.log(`token0 deployed to ${token0.address}`);
  console.log(`token1 deployed to ${token1.address}`);

  const Pair = await ethers.getContractFactory("pair");
  const pair = await Pair.deploy(token0.address, token1.address);
  await pair.deployed();
  console.log(`Pair deployed to ${pair.address}`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
