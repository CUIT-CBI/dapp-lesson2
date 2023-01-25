import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
  
  const tokenA = await FT.deploy("WLA", "WLA");
  const tokenB = await FT.deploy("WLB", "WLB");
  await tokenA.deployed();
  await tokenB.deployed();

  const WL = await ethers.getContractFactory("finalwork");
  const wanlon = await finalwork.deploy(tokenA.address, tokenB.address);
  await wanlon.deployed();

  console.log(`FT deployed to ${tokenA.address}`);
  console.log(`FT deployed to ${tokenB.address}`);


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
