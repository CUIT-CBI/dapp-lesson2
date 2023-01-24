import '@nomiclabs/hardhat-ethers';
import { config } from 'chai';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("DMS", "CUIT202");
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`)

  const FPair = await ethers.getContractFactory("DMSPair");
  const fpair = await FPair.deploy();
  await fpair.deployed();
  console.log(`pair deployed to ${fpair.address}`);

  const FV2Router = await ethers.getContractFactory("Router")
  const frouter = await FV2Router.deploy(fpair.address);
  await frouter.deployed();
  console.log(`Router deployed to ${frouter.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
