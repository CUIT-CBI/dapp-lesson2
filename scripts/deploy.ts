import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const token0 = await FT.deploy("CBI", "CUIT");
  await token0.deployed();
  console.log(`token0 deployed to ${token0.address}`);
  const token1 = await FT.deploy("XiaoKe", "XK");
  await token1.deployed();
  console.log(`token1 deployed to ${token1.address}`);

  const Pair = await ethers.getContractFactory("Pair");
  const pair = await Pair.deploy(token0.address,token1.address);
  console.log(`pair deployed to ${pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
