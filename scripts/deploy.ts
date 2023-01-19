import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

  const FT = await ethers.getContractFactory("FT");
  const Factory = await ethers.getContractFactory("tokenFactory");
  const tokenA = await FT.deploy("A", "A");
  const tokenB = await FT.deploy("B", "B");
  await tokenA.deployed();
  await tokenB.deployed();
  console.log(`FT deployed to ${tokenA.address}`);
  console.log("FT address:",tokenB.address);

  const factory = await Factory.deploy();
  await factory.deployed();
  console.log(`factory address:${factory.address}`);

  await factory.createPair(tokenA.address,tokenB.address,"0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199");
  const pairAddress = await factory.getPair(tokenA.address,tokenB.address);
  const pairFactory = await ethers.getContractFactory("tokenPair");
  const pair =  pairFactory.attach(pairAddress);

  await pair.deployed()
  console.log(`pair address: ${pair.address}`)
  console.log(`tokenA: ${await pair.A()} tokenB: ${await pair.B()}`)


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
