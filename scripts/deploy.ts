import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy(ft.address);

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
  await factory.deployed();
  console.log(`Factory deployed to ${factory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
