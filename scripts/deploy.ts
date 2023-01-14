import '@nomiclabs/hardhat-ethers';
// @ts-ignore
import { ethers } from "hardhat";

async function main() {
  const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("Token1", "FT1");
  await ft1.deployed();
  console.log(`Token1 address: ${ft1.address}`);
  const FT2 = await ethers.getContractFactory("FT");
  const ft2 = await FT2.deploy("Token2", "T2");
  await ft2.deployed();
  console.log(`Token2 address: ${ft2.address}`);
  const Uniswap = await ethers.getContractFactory("UniswapLSH");
  const uniswap = await Uniswap.deploy(ft1.address,ft2.address);
  await uniswap.deployed();
  console.log(`Uniswap address: ${uniswap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
