import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("Wuchang", "WC");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  const Token = await ethers.getContractFactory("token");
  const DeployToken = await Token.deploy();

  await DeployToken.deployed();
  console.log(`token deployed to ${DeployToken.address}`);

  const Exchange = await ethers.getContractFactory("TokenExchange");
  const TokenExchange = await Exchange.deploy(DeployToken.address);

  await TokenExchange.deployed();
  console.log(`TokenExchange deployed to ${TokenExchange.address}`);
  }
