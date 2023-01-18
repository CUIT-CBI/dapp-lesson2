import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
async function main() {
  const T1 = await ethers.getContractFactory("FT");
  const t1 = await T1.deploy("wml","wsl");

  const T2 = await ethers.getContractFactory("FT");
  const t2 = await T2.deploy("lmw","lsw");
  

  const zzzz = await ethers.getContractFactory("Exchange");
  const z1z = await zzzz.deploy('zzzzzz', 'zwzwzw');

  await z1z.deployed();

  console.log(`t1address: ${t1.address} t2address: ${t2.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
