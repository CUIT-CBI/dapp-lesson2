import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("CBI", "CUIT");
  const tokenB = await FT.deploy("LD", "LZQ");

  await tokenA.deployed();
  await tokenB.deployed();
  console.log(`tokenA deployed to ${tokenA.address}`);
  console.log(`tokenB deployed to ${tokenB.address}`);
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy();
  await factory.deployed();
  console.log(`factory deployed to ${factory.address}`);
  const Router = await ethers.getContractFactory("Router");
  const router = await Router.deploy(factory.address);
  await router.deployed();
  console.log(`router deployed to ${router.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});