import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();

  const token0 = await FT.deploy("token0", "ZP0");
  await token0.deployed();
  const token1 = await FT.deploy("token1", "ZP1");
  await token1.deployed();
  const exchange = await FT.deploy(token0.address,token1.address);
  await exchange.deployed();

  console.log(`FT deployed to ${ft.address}`);

  console.log(`token0 address: ${token0.address}`);
  console.log(`token1 address: ${token1.address}`);
  console.log(`exchange address: ${exchange.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
