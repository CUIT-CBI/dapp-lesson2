import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);


  const FT0 = await ethers.getContractFactory("FT");
  const ft0 = await FT0.deploy("Token0", "FT0");

  await ft0.deployed();
  console.log(`Token0 address: ${ft0.address}`);

  const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("Token2", "FT1");
  await ft1.deployed();
  console.log(`Token1 address: ${ft1.address}`);

  const Uniswap = await ethers.getContractFactory("uniswapLZW");
  const uniswap = await Uniswap.deploy(ft0.address, ft1.address);
  await uniswap.deployed();
  console.log(`uniswapLZW deployed to: ${uniswap.address}`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
