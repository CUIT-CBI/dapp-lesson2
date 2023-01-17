import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  //部署第一种erc20代币
  const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("token1", "t1");

  //部署第二种erc20代币
  const FT2 = await ethers.getContractFactory("FT");
  const ft2 = await FT2.deploy("token2", "t2");

  //以上面两种代币作为币对部署交易池
  const SwapPool = await ethers.getContractFactory("SwapPool");
  const swappool = await SwapPool.deploy(ft1.address,ft2.address);

  //等待部署
  await ft1.deployed();
  await ft2.deployed();
  await swappool.deployed();

  console.log(`FT1 deployed to ${ft1.address}`);
  console.log(`FT2 deployed to ${ft2.address}`);
  console.log(`SwapPool deployed to ${swappool.address}`);
  //console.log(`token0:${await swappool.token0()}; token1:${await swappool.token1()}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
