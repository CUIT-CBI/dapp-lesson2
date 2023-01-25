import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";


async function main() {
    const FT = await ethers.getContractFactory("FT");

    const tokenA = await FT.deploy("TokenA", "ZYQ");
    await tokenA.deployed();
    console.log(`tokenA deployed to ${tokenA.address}`);

    const tokenB = await FT.deploy("TokenB", "zyq");
    await tokenB.deployed();
    console.log(`tokenB deployed to ${tokenB.address}`);

    const TokenSwap = await FT.deploy(tokenA.address, tokenB.address);
    await TokenSwap.deployed();
    console.log(`Pair deployed to ${TokenSwap.address}`);





  }


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
