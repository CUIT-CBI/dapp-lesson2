import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");

  const token0 = await FT.deploy("CBI", "CUIT");
  await token0.deployed();
  console.log(`token0 deployed to ${token0.address}`);

  const token1 = await FT.deploy("CBI", "CUIT");
  await token1.deployed();
  console.log(`token1 deployed to ${token1.address}`);

  const Uniswap = await ethers.getContractFactory("Uniswap");
  const swap = await Uniswap.deploy(token0.address,token1.address);
  await swap.deployed();
  console.log(`swap deployed to ${swap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
