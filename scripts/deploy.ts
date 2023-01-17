import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  //部署FT，得到两种代币
  const FT = await ethers.getContractFactory("FT");
  const token1 = await FT.deploy("CBI", "CUIT");
  const token2 = await FT.deploy("LvHongwei", "LHW");
  
  await token1.deployed();
  await token2.deployed();
  console.log(`token1 deployed to ${token1.address}`);
  console.log(`token2 deployed to ${token2.address}`);

  //部署pool，得到对应两种代币的实例domo
  const pool = await ethers.getContractFactory("pool");
  const demo = await pool.deploy(token1.address, token2.address);

  await demo.deployed();
  console.log(`demo deployed to ${demo.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
