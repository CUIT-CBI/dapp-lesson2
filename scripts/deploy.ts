import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const token0 = await FT.deploy("LLZ","LLZ"); 
  const token1 = await FT.deploy("llz","llz"); 
  const Pair = await ethers.getContractFactory("Pair");
  const pair = await Pair.deploy(token0.address,token1.address);
  const Factory = await ethers.getContractFactory("Factory");
  const fc = await Factory.deploy();
  await ft.deployed();
  await pair.deployed();
  await fc.deployed();
  console.log(`FT deployed to ${ft.address}`);
  console.log(`Pair deployed to ${pair.address}`);
  console.log(`Factory deplyed to ${fc.address}`);
  await token0.setPair(token0.address);
  await token0.setPair(token1.address);
  await token0.mint(token0.address,5000000000);
  await token1.mint(token1.address,5000000000);
  const pairs = await fc.createPair(token0.address,token1.address);
  console.log("addressPair:",pairs)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
