import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("ZYX", "CUIT201");
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  const Ztoken = await ethers.getContractFactory("Ztoken");
  const ztoken = await Ztoken.deploy();
  await ztoken.deployed();
  console.log(`Ztoken deployed to ${ztoken.address}`);

  const ZtokenFactory = await ethers.getContractFactory("ZtokenFactory")
  const ztokenFactory = await ZtokenFactory.deploy();
  await ztokenFactory.deployed();
  console.log(`ZtokenFactory deployed to ${ztokenFactory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
