import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
let deployer
async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("CBI", "CUIT");
  const token1 = await FT.deploy("CBI", "CUIT");
  const token2 = await FT.deploy("ZYH", "ZYH");
  const Factory = await ethers.getContractFactory("Factory");
  const factory = await Factory.deploy(ft.address);

  await ft.deployed();
  console.log(`FT deployed to ${ft.address}`);
  await token1.setPair(deployer.address)
  await token2.setPair(deployer.address)
  await token1.mint(deployer.address,10000000)
  await token2.mint(deployer.address,10000000)
  await token1.approve(factory.address,10000000)
  await token2.approve(factory.address,10000000)
  await factory.deployed();
  console.log(`Factory deployed to ${factory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});