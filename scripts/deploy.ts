import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  console.log('默认部署到heco_testnet');
  const FT1 = await ethers.getContractFactory("FT");
  const ft1 = await FT1.deploy("TEST1", "T1");
  await ft1.deployed();
  console.log(`The First FT deployed to ${ft1.address}`);
  const FT2 = await ethers.getContractFactory("FT");
  const ft2 = await FT2.deploy("TEST2", "T2");
  await ft2.deployed();
  console.log(`The Second FT deployed to ${ft2.address}`);
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy();
  await factory.deployed();
  console.log(`Factory deployed to ${factory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
