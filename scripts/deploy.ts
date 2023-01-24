import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
let deployer;
async function main() {
  [deployer] = await ethers.getSigners();
  const FT = await ethers.getContractFactory("FT");
  const token1 = await FT.deploy("CUBI", "cubi");
  await token1.deployed();
  console.log(`token1 deployed to ${token1.address}`);
  const token2 = await FT.deploy("XuJie", "XJ");
  await token2.deployed();
  console.log(`token2 deployed to ${token2.address}`);


  const Pair = await ethers.getContractFactory("Pair");
  const pair = await Pair.deploy(token1.address,token2.address);
  console.log(`pair deployed to ${pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

