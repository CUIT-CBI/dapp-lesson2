import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {

    // 创建部署 coinA 和 coinB
  const FT = await ethers.getContractFactory("FT");
  const uniswapFactory = await ethers.getContractFactory("factory");
  const coin_A = await FT.deploy("coin_A", "coin_A");
  await coin_A.deployed();
  console.log(`coin_A deployed to ${coin_A.address}`);
  
  const coin_B = await FT.deploy("coin_B", "coin_B");
  await coin_B.deployed();
  console.log("coin_B address:",coin_B.address);

  const Factory = await uniswapFactory.deploy();
  await Factory.deployed();
  console.log(`uniswapFactory address:${uniswapFactory.address}`);

  // 使用 factory创建uniswap合约
  await Factory.createPair(coin_A.address,coin_B.address,"平台方的地址");
  const uniswapAddress = await Factory.getPair(coin_A.address,coin_B.address);
  const Contract = await ethers.getContractFactory("swap");
  const uniswap =  Contract.attach(uniswapAddress);

  await uniswap.deployed()
  console.log(`uniswap address: ${uniswap.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
