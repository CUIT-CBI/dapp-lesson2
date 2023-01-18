import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const Dex = await ethers.getContractFactory("Dex");
  const dex = await FT.deploy();

  await dex.deployed();
  console.log(`Dex contract deployed to ${dex.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
