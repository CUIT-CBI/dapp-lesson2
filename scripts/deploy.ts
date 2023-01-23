import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("xzwA", "xzwA");
  const tokenB = await FT.deploy("xzwB", "xzwB");
  await tokenA.deployed();
  await tokenB.deployed();

  const XZW = await ethers.getContractFactory("XZW");
  const XZWWZX = await XZW.deploy(tokenA.address, tokenB.address);
  await XZWWZX.deployed();

  console.log(`FT deployed to ${tokenA.address}`);
  console.log(`FT deployed to ${tokenB.address}`);

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
