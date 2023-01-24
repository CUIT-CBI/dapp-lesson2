import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";


async function main() {
    const FT = await ethers.getContractFactory("FT");
    
    const token1 = await FT.deploy("Token1", "LYX");
    await token1.deployed();
    console.log(`token1 deployed to ${token1.address}`);

    const token2 = await FT.deploy("Token2", "lyx");
    await token2.deployed();
    console.log(`token2 deployed to ${token2.address}`);

    const TokenSwap = await FT.deploy(token1.address, token2.address);
    await TokenSwap.deployed();
    console.log(`Pair deployed to ${TokenSwap.address}`);
  
    
    
    
    
  }


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
