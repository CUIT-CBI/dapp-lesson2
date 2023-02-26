import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const token1="11111";
  const token2="22222";

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
  const PAIR = await ethers.getContractFactory("WSCPair");
  const pair = await PAIR.deploy(token1, token2);

  await pair.deployed();
  console.log(`pair deployed to ${pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
