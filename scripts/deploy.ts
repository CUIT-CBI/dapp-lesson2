import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("MyUniswap", "CKR");
  await ft.deployed();
  
  const token0 = await FT.deploy("token0", "CKR0");
  await token0.deployed();

  const token1 = await FT.deploy("token1", "CKR1");
  await token1.deployed();

  const MyUniswap = await FT.deploy(token0.address,token1.address);
  await MyUniswap.deployed();

  console.log(`FT deployed to ${ft.address}`);
  console.log(`token0 deployed to ${token0.address}`);
  console.log(`token1 deployed to ${token1.address}`);
  console.log(`MyUniswap deployed to ${MyUniswap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
