import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("YZW", "Y");
  await tokenA.deployed();
  const tokenB = await FT.deploy("YZW", "Z");
  await tokenB.deployed();

  const swap = await ethers.getContractFactory("swap");
  const swaped = await swap.deploy(tokenA.address, tokenB.address);
  await swaped.deployed();

  console.log(`FT deployed to ${tokenA.address}`);
  console.log(`FT deployed to ${tokenB.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
