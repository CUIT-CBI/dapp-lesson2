import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  //部署GcyERC20合约
  const PairToken = await ethers.getContractFactory("GcyERC20");
  const tokenA = await PairToken.deploy("tokenA", "TKA");
  await tokenA.deployed();
  console.log(`tokenA deployed to: ${tokenA.address}`);
  const tokenB = await PairToken.deploy("tokenB", "TKB");
  await tokenB.deployed();
  console.log(`tokenB deployed to: ${tokenB.address}`);
  //部署GcyPool合约
  const Pool = await ethers.getContractFactory("GcyPool");
  const pool = await Pool.deploy(tokenA.address, tokenB.address);
  await pool.deployed();
  console.log(`Pool deployed to: ${pool.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
