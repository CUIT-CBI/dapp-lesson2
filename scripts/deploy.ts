import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

let deployer;
async function main() {
  [deployer] = await ethers.getSigners();
  const FT = await ethers.getContractFactory("FT");
  const token1 = await FT.deploy("CBI", "CUIT");
  const token2 = await FT.deploy("ZXJ", "ZXJ");
  const Factory = await ethers.getContractFactory("tokenFactory");
  const factory = await Factory.deploy();

  await token1.setPair(deployer.address)
  await token2.setPair(deployer.address)
  await token1.mint(deployer.address,10000000)
  await token2.mint(deployer.address,10000000)
  await token1.approve(factory.address,10000000)
  await token2.approve(factory.address,10000000)
  const pair = await factory.connect(deployer).creatPair(token1.address,token2.address,1,100)
  await pair.wait()
  console.log(pair)
  console.log("token1's address : ", token1.address, "\n"+
              "token2's address : ", token2.address, "\n" +
              "Factory's address : ", factory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
