import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const MyToken = await ethers.getContractFactory("MyToken");
  const myToken =await MyToken.deploy();
  await myToken.deployed();
  console.log("Token Address:", myToken.address);
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT",myToken.address);
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
