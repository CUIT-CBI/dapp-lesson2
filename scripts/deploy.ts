import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("CBI", "CUIT");
  await tokenA.deployed();
  const tokenB = await FT.deploy("WJY", "WJY");
  await tokenB.deployed();
  const funcRealize = await FT.deploy(tokenA.address, tokenB.address);
  await funcRealize.deployed();

  console.log(`token1 deployed to ${tokenA.address}`);
  console.log(`token2 deployed to ${tokenB.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});