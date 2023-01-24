import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

  async function main() {

    const FT = await ethers.getContractFactory("FT");
    const ft = await FT.deploy("CBI", "CUIT");
    const Factory = await ethers.getContractFactory("TokenUse");
    const tokenA = await FT.deploy("A", "A");
    const tokenB = await FT.deploy("B", "B");
    await tokenA.deployed();
    await tokenB.deployed();
    console.log(`FT deployed to ${tokenA.address}`);
    console.log("FT address:",tokenB.address);
  
    const factory = await Factory.deploy();
    await factory.deployed();
    console.log(`factory address:${factory.address}`);
  
    await factory.createPair(tokenA.address,tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address,tokenB.address);
    const pairFactory = await ethers.getContractFactory("tokenPair");
    const pair =  pairFactory.attach(pairAddress);
  
    await pair.deployed()
    console.log(`pair address: ${pair.address}`)
    console.log(`tokenA: ${await pair.A()} tokenB: ${await pair.B()}`)
  
  
    await ft.deployed();
    console.log(`FT deployed to ${ft.address}`);
  };
