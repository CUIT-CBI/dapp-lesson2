import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();
  const tokena = await FT.deploy("tokena", "W1");
  await tokena.deployed();
  const tokenb = await FT.deploy("tokenb", "W2");
  await tokenb.deployed();

  console.log(`FT deployed to ${ft.address}`);
  console.log(`tokena deployed to ${tokena.address}`);
  console.log(`tokenb deployed to ${tokenb.address}`);

}