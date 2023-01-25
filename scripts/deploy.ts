import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  // 部署ERC20合约
  const PairToken = await ethers.getContractFactory("ERC20");
  const tokenA = await PairToken.deploy("tokenA", "TKA");
  await tokenA.deployed();
  console.log(`tokenA deployed to: ${tokenA.address}`);
  const tokenB = await PairToken.deploy("tokenB", "TKB");
  await tokenB.deployed();
  console.log(`tokenB deployed to: ${tokenB.address}`);
  // 部署SwapPool合约
  const SwapPool = await ethers.getContractFactory("SwapPool");
  const swappool = await SwapPool.deploy(tokenA.address, tokenB.address);
  await swappool.deployed();
  console.log(`SwapPool deployed to: ${swappool.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
