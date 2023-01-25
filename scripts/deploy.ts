import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  async function main() {

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
}
    const FT = await ethers.getContractFactory("FT");
    const SwapPool = await ethers.getContractFactory("SwapPool");
    const token0 = await FT.deploy("token0", "t0");
    const token1 = await FT.deploy("token1", "t1");
    await token0.deployed();
    await token1.deployed();


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
    const factory = await  SwapPool.deploy();
    await factory.deployed();
    console.log(`factory address:${factory.address}`);

    await factory.createPair(token0.address,token1.address);
    const pairAddress = await factory.getPair(token0.address,token1.address);
    const pairFactory = await ethers.getContractFactory("tokenPair");
    const pair =  pairFactory.attach(pairAddress);
    await pair.deployed()

  };
