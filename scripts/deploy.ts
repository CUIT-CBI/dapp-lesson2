import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();

  const token0 = await FT.deploy("token0","SZY_A");
  await token0.deployed();

  const token1 = await FT.deploy("token1","SZY_B");
  await token1.deployed();

  
  const Pair = await FT.deployed(ft.address,token0.address,token1.address);
  await Pair.deployed();
  console.log(`FT deployed to ${ft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
