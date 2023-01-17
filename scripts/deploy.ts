import '@nomiclabs/hardhat-ethers';
import { config } from 'chai';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("FW", "CUIT202");
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`)

  const FPair = await ethers.getContractFactory("FPair");
  const fpair = await FPair.deploy();
  await fpair.deployed();
  console.log(`Fpair deployed to ${fpair.address}`);

  const FV2Router = await ethers.getContractFactory("FV2Router")
  const frouter = await FV2Router.deploy(fpair.address);
  await frouter.deployed();
  console.log(`FRouter deployed to ${frouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
