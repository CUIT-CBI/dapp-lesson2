import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
  const uniswapV2Factory = await UniswapV2Factory.deploy();

  await uniswapV2Factory.deployed();

  const WETH = await ethers.getContractFactory("WETH9");
  const wETH = await WETH.deploy();

  await wETH.deployed();

  const Uniswap = await ethers.getContractFactory("uniswap");
  const uniswap = await  Uniswap.deploy(uniswapV2Factory.address,wETH.address);

  await uniswap.deployed();

  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");

  await ft.deployed();


  console.log(`FT deployed to ${ft.address}`);
  console.log(`UniswapV2Factory deployed to ${uniswapV2Factory.address}`);
  console.log(`WETH deployed to ${wETH.address}`);
  console.log(`Uniswap deployed to ${uniswap.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
