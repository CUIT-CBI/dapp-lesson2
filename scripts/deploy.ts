import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const token1 = await FT.deploy("CBI", "CUIT");
  await token1.deployed();
  const token2 = await FT.deploy("WHM", "WHM");
  await token2.deployed();
  const Pair = await FT.deploy(token1.address, token2.address);
  await Pair.deployed();

  console.log(`token1 deployed to ${token1.address}`);
  console.log(`token2 deployed to ${token2.address}`);
  console.log(`Pair deployed to ${Pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
