import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();
  const token1 = await FT.deploy("token1", "CBI");
  await token1.deployed();
  const token2 = await FT.deploy("token2", "CBI");
  await token2.deployed();
  console.log(`FT deployed to ${ft.address}`);
   console.log(`token1 deployed to ${token1.address}`);
  console.log(`token2 deployed to ${token2.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
