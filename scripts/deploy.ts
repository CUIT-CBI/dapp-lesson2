import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const Uniswap=await ethers.getContractFactory("Uniswap");
  const uniswap = await Uniswap.deploy();
  await uniswap.deployed;
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
  console.log(`Uniswap is deployed to ${uniswap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
