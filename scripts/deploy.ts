import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const token0 = "0x0fffffffffffffffffffffffffffff";    
  const token1 = "0x000000000000000000000000000000"; 

  const WZYPairFactory = await ethers.getContractFactory('WZYPair');
  const WZYPair = await WZYPairFactory.deploy(token0, token1,3);
  await WZYPair.deployed();
  console.log(`WzyPair deployed to ${WZYPair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
