import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  const Swap = await ethers.getContractFactory("Swap");
  const swap = await Swap.deploy();

  await swap.deployed();
  console.log(`Swap deployed to ${swap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
