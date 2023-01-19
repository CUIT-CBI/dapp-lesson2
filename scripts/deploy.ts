import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

  const Token1 = await ethers.getContractFactory("FT");
  const token1 = await Token1.deploy("Token1", "token1");
  await token1.deployed();
  console.log(`Token1: ${token1.address}`);

  const Token2 = await ethers.getContractFactory("FT");
  const token2 = await Token2.deploy("Token2", "token2");
  await token2.deployed();
  console.log(`Token2: ${token2.address}`);

  const Factory = await ethers.getContractFactory("Exchange");
  const factory = await Factory.deploy(token1.address,token2.address);
  await factory.deployed();
  console.log(`Uniswap: ${factory.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

