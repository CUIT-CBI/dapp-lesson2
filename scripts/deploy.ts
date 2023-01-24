import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  
  const mmzFactory = await ethers.getContractFactory("factory");
  const factory = await mmzFactory.deploy()
  console.log(`Factory deployed to ${factory.address}`);
  const FT = await ethers.getContractFactory("FT");
  const Token0 = await FT.deploy("Token0", "token0");
  console.log(`Token0 deployed to ${Token0.address}`);
  const Token1 = await FT.deploy("Token1", "token1");
  console.log(`Token1 deployed to ${Token1.address}`);
  const mmzSwap = await factory.createPair(Token0.address, Token1.address); // 部署币对池子，返回是一个contractTransaction
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});