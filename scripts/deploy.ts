import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("tokenA", "A");
  const tokenB = await FT.deploy("tokenB", "B");
  await tokenA.deployed();
  await tokenB.deployed();
  console.log(`FT deployed to ${tokenA.address}`);
  console.log(`FT deployed to ${tokenB.address}`);

  const uniswap = await ethers.getContractFactory("uniswap");
  await uniswap.deployed(tokenA.address,tokenB.address,"0x受益者地址");
  console.log(`uniswap地址是:${uniswap.address}`);


}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

