import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("ZC", "ZC");

  const Exchange = await ethers.getContractFactory("Exchange");
  const exchange = await Exchange.deploy(ft.address);

  // await ft.deployed();
  // console.log(`FT deployed to ${ft.address}`);

  await exchange.deployed();
  console.log(`Exchange deployed to ${exchange.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
