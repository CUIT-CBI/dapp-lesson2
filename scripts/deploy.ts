import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  const FT0 = await ethers.getContractFactory("FT");
  const ft0 = await FT0.deploy("Token0", "FT0");

  await ft0.deployed();
  console.log(`Token0 address: ${ft0.address}`);

  const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("Token1", "FT1");
  await ft1.deployed();
  console.log(`Token1 address: ${ft1.address}`);

  const Business = await ethers.getContractFactory("HYXbusiness");
  const business = await Business.deploy(ft0.address, ft1.address);
  await business.deployed();
  console.log(`HYX deployed to: ${business.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
