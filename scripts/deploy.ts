import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
    // 获取第一个账户，用来部署合约
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];

    // 部署第一种代币
    const FT1 = await ethers.getContractFactory("FT");
    const ft1 = await FT1.deploy("token1", "t1", 18, {from: deployer});
    await ft1.deployed();
    console.log(`token1 contract deployed at address: ${ft1.address}`);

    // 部署第二种代币
    const FT2 = await ethers.getContractFactory("FT");
    const ft2 = await FT2.deploy("token2", "t2", 18, {from: deployer});
    await ft2.deployed();
    console.log(`token2 contract deployed at address: ${ft2.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
