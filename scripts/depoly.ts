import { ethers } from "hardhat";
async function main() {
    const FT = await ethers.getContractFactory("FT");
    
    const token1 = await FT.deploy("Token1", "HK");
    await token1.deployed();
    const token2 = await FT.deploy("Token2", "hk");
    await token2.deployed();
    const Swap = await FT.deploy(token1.address, token2.address);
    await Swap.deployed();
  
    
    console.log(`token1 deployed to ${token1.address}`);
    console.log(`token2 deployed to ${token2.address}`);
    console.log(`Pair deployed to ${Swap.address}`);
  }

  