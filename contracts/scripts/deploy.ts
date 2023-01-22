import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("Liu Wei", "LW");

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);

    // 部署Factory合约
  const LWFactory = await ethers.getContractFactory("LWFactory");
  const Factory = await LWFactory.deploy();
  await Factory.deployed();
  console.log(`Factory deployed to ${Factory.address}`);

  //部署pair合约
  const LWPair = await ethers.getContractFactory("LWPair");
  const Pair = await LWPair.deploy();
  await Pair.deployed();
  console.log(`Pair deployed to ${Pair.address}`);
}

