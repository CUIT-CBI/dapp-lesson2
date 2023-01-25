import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();

  const token0 = await FT.deploy("token0", "t0");
  await token0.deployed();
  const token1 = await FT.deploy("token1", "t1");
  await token1.deployed();
  const contract = await FT.deploy(token0.address, token1.address);
  await contract.deployed();
}