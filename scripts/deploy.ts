import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

<<<<<<< HEAD
  const Token = await ethers.getContractFactory("WuChang");
  const token = await Token.deploy();

  await token.deployed();
  console.log(`token deployed to ${token.address}`);

  const TokenExchange = await ethers.getContractFactory("TokenExchange");
  const exchange = await TokenExchange.deploy(token.address);

  await exchange.deployed();
  console.log(`exchange deployed to ${exchange.address}`);
  }
=======
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
>>>>>>> a8a9cc311c2690034eb386fad7c00f0b5bc39ed7
