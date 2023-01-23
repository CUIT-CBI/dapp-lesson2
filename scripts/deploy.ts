import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
    const tokenA = "0x0000000000000000";    
    const tokenB = "0x1111111111111111";    

    const DexPair = await ethers.getContractFactory('DexPair');
    const dexpair = await DexPair.deploy(tokenA, tokenB);

    await dexpair.deployed();
    console.log(`Contract deployed to ${dexpair.address}`);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

