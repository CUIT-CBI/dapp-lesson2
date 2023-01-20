import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

let deployer;
async function main() {
  [deployer] = await ethers.getSigners();
  const FT = await ethers.getContractFactory("FT");
  const token1 = await FT.deploy("CBI", "CUIT");
  const token2 = await FT.deploy("CKH", "CKH");
  const Factory = await ethers.getContractFactory("tokenFactory");
  const factory = await Factory.deploy();
  await token1.mint(deployer.address,100)
  await token2.mint(deployer.address,100)
  await token1.approve(factory.address,100)
  await token2.approve(factory.address,100)
  const pair = await factory.connect(deployer).creatPairs(token1.address,token2.address,1,100)
  await pair.wait()
  console.log(pair)
  console.log("AddressOfToken1: ", token1.address, "\n" + "AddressOfToken2: ", token2.address, "\n" + "AddressOfFactory : ", factory.address);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

