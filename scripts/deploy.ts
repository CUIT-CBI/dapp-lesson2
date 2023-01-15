import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("Wuchang", "WC");

//   await ft.deployed();
//   console.log(`FT deployed to ${ft.address}`);

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

  const Exchange = await ethers.getContractFactory("TokenExchange");
  const TokenExchange = await Exchange.deploy(ft.address);
  
  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  await TokenExchange.deployed();
  console.log(`TokenExchange deployed to ${TokenExchange.address}`);
  }
