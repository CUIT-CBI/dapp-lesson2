import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
    const tokenA = "0x0000000000000000";    
    const tokenB = "0x1111111111111111";    

    const PmlPair = await ethers.getContractFactory('PmlPair');
    const pmlpair = await PmlPair.deploy(tokenA, tokenB);

    await pmlpair.deployed();
    console.log(`Contract deployed to ${pmlpair.address}`);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
