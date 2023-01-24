import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const factory = await ethers.getContractFactory("CsdswapFactory");
  const ft = await factory.deploy();

  await ft.deployed();
  const token0="0xfffffffffffffffffffffffffff";
  const token1="0x666666666666666666666666666";
  await ft.createPair(token0,token1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
