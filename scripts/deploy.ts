import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
    const FT = await ethers.getContractFactory("FT");

    const token_1 = await FT.deploy("Token1", "LYJ_1");
    await token_1.deployed();
    console.log(`token_1 deployed to ${token_1.address}`);

    const token_2 = await FT.deploy("Token2", "LYJ_2");
    await token_2.deployed();
    console.log(`token_2 deployed to ${token_2.address}`);

    const TokenSwap = await FT.deploy(token_1.address, token_2.address);
    await TokenSwap.deployed();
    console.log(`Pair deployed to ${TokenSwap.address}`);
  }

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
