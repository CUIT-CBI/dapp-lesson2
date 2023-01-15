import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const token0 = await FT.deploy("CBI","CUIT");
  await token0.deployed();
  console.log(`Token0 deployed to ${token0.address}`);
  const token1 = await FT.deploy("ZC","ZC");
  await token1.deployed();
  console.log(`Token1 deployed to ${token1.address}`);

  const Exchange = await ethers.getContractExchange("Exchange");
  const exchange = await Exchange.deploy();
  await exchange.deployed();
  console.log(`Exchange deployed to ${exchange.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
