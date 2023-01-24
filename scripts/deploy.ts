import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
 const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("tokenA", "FT1");
  await ft1.deployed();
  console.log(`tokenA address: ${ft1.address}`);
  const FT2 = await ethers.getContractFactory("FT");
  const ft2 = await FT2.deploy("tokenB", "FT2");
  await ft2.deployed();
  console.log(`tokenB address: ${ft2.address}`);
  const Uniswap = await ethers.getContractFactory("UniswapPair");
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
