import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  // 部署工厂创建合约
  const wkFactory = await ethers.getContractFactory("Factory");
  const factory = await wkFactory.deploy()
  console.log(`Factory deployed to ${factory.address}`);

  // 部署TokenA, TokenB合约
  const FT = await ethers.getContractFactory("FT");
  const TokenA = await FT.deploy("TokenA", "[A]");
  console.log(`Token0 deployed to ${TokenA.address}`);
  const TokenB = await FT.deploy("TokenB", "[B]");
  console.log(`Token1 deployed to ${TokenB.address}`);

  // 创建币对交易池子
  const wkSwap = await factory.createPair(TokenA.address, TokenB.address);
  console.log(`Swap deployed to ${wkSwap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});