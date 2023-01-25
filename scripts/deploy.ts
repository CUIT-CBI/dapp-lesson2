import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("GSY", "CBI");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  const UniswapV2Pair = await ethers.getContractFactory("UniswapV2Pair");
  const uniswapV2Pair = await UniswapV2Pair.deploy();

  await uniswapV2Pair.deployed();
  console.log(`FT deployed to ${uniswapV2Pair.address}`);

  const Exchange = await ethers.getContractFactory("Exchange");
  const exchange = await Exchange.deploy();

  await exchange.deployed();
  console.log(`FT deployed to ${exchange.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
