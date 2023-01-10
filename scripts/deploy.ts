import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("ZC", "ZC");

  //ContractFactory是用于部署新智能合约的抽象，
  //exchangeContract是Exchange合约实例的工厂
  const exchangeContract = await FT.getContractFactory("Exchange");
  const deployedExchangeContract = await exchangeContract.deploy(ft.address);

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

  await deployedExchangeContract.deployed();
  console.log(`exchangeContract deployed to ${deployedExchangeContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
