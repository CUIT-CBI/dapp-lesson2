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
  const exchange = await Exchange.deploy(token0.address, token1.address);
  await exchange.deployed();
  console.log(`Exchange deployed to ${exchange.address}`);

  const Factory = await ethers.getContractExchange("Pair");
  const factory = await Factory.deploy(token0.address, token1.address);
  await factory.deployed();
  console.log(`Factory deployed to ${factory.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
