import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  await ft.deployed();
  const token1 = await FT.deploy("token1", "YKX1");
  await token1.deployed();
  const token2 = await FT.deploy("token2", "YKX2");
  await token2.deployed();
  const contract = await FT.deploy(ft.address, token1.address, token2.address);
  await contract.deployed();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
