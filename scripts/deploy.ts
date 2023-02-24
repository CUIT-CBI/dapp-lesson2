import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
let deployer
async function main() {
  const FT = await ethers.getContractFactory("FT");
  const tokenA = await FT.deploy("YZW", "Y");
  await tokenA.deployed();
  const tokenB = await FT.deploy("YZW", "Z");
  await tokenB.deployed();

  const swap = await ethers.getContractFactory("swap");
  const swaped = await swap.deploy(tokenA.address, tokenB.address);
  await swaped.deployed();

  console.log(`FT deployed to ${tokenA.address}`);
  console.log(`FT deployed to ${tokenB.address}`);

  [deployer] = await ethers.getSigners();
  const provider = await ethers.providers.getDefaultProvider();
  const WETHContract = await ethers.getContractFactory("WETH");
  const WETH = await WETHContract.deploy();
  await WETH._deployed();
  const factoryContract = await ethers.getContractFactory("Factory");
  const factory = await factoryContract.deploy(); 
  await factory.deployed();
  const routerContract = await ethers.getContractFactory("Router");
  const router = await routerContract.deploy(factory.address, WETH.address);
  await router.deployed();
  const stakerpoolContract = await ethers.getContractFactory("GzxERC20");
  const stakerpool = await stakerpoolContract.deploy();
  await WETH._deployed();
  let blocknumber_pre = provider.getBlockNumber();
  const stakerContract = await ethers.getContractFactory("StakerMain");
  const staker = await stakerContract.deploy(stakerpool.address, deployer.address, blocknumber_pre, 999999999, provider.getBlockNumber());
  await WETH._deployed();
  console.log("WETH's address : ", WETH.address, "\n"+
              "Factory's address : ", factory.address, "\n"+
              "Router's address : ", router.address, "\n" +
              "staker's address : ", staker.address);

  //有关滑点的计算可以写一个js，类似于uniswap-sdk Trader的实现，时间关系就不做此算法了。
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
