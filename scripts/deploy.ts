import '@nomiclabs/hardhat-ethers';
// @ts-ignore
import hre, { ethers } from "hardhat";

async function main() {

  // token0
  const Token0 = await ethers.getContractFactory("FT");
  const token0 = await Token0.deploy("token0", "CUIT");

  await token0.deployed();
  console.log(`token0 deployed to ${token0.address}`);

  // token1
  const Token1 = await ethers.getContractFactory("FT");
  const token1 = await Token1.deploy("token1", "CUIT");

  await token1.deployed();
  console.log(`token1 deployed to ${token1.address}`);

  // pair
  const Pair = await ethers.getContractFactory("uniswapV2Pair");
  const pair = await Pair.deploy(token0.address, token1.address);

  await pair.deployed();
  console.log(`pair deployed to ${pair.address}`);

  // router
  const Router = await ethers.getContractFactory("uniswapV2Router");
  const router = await Router.deploy(pair.address);

  await router.deployed();
  console.log(`router deployed to ${router.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
