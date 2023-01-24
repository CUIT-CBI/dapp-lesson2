import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const token0 = await FT.deploy("TSY","TSY"); 
  const token1 = await FT.deploy("teng","teng"); 
  const Pair = await ethers.getContractFactory("pair");
  const pair = await Pair.deploy(token0.address,token1.address);
  await ft.deployed();
  await pair.deployed();
  console.log(`FT deployed to ${ft.address}`);
  console.log(`Pair deployed to ${pair.address}`);
  await token0.setPair(token0.address);
  await token0.setPair(token1.address);
  await token0.mint(token0.address,1000000000);
  await token1.mint(token1.address,1000000000);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
