import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

  const Token = await ethers.getContractFactory("WuChang");
  const token = await Token.deploy();

  await token.deployed();
  console.log(`token deployed to ${token.address}`);

  const TokenExchange = await ethers.getContractFactory("TokenExchange");
  const exchange = await TokenExchange.deploy(token.address);

  await exchange.deployed();
  console.log(`exchange deployed to ${exchange.address}`);
  }