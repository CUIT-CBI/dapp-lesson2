import { ethers } from "hardhat";

async function main() {
    console.log("============= TokenSwap Deployment Start =============");

    const TokenA_Factory = await ethers.getContractFactory('TokenA');
    const TokenA = await TokenA_Factory.deploy();
    await TokenA.deployed();
    const TokenA_address = TokenA.address;
    console.log(`TokenA has been deployed at ${TokenA_address}`);

    const TokenB_Factory = await ethers.getContractFactory('TokenB');
    const TokenB = await TokenB_Factory.deploy();
    await TokenB.deployed();
    const TokenB_address = TokenB.address;
    console.log(`TokenB has been deployed at ${TokenB_address}`);

    const TokenSwap_Factory = await ethers.getContractFactory('TokenSwap');
    const TokenSwap = await TokenSwap_Factory.deploy(TokenA_address, TokenB_address);
    await TokenSwap.deployed();
    console.log(`TokenSwap has been deployed at ${TokenSwap.address}`);

    console.log("============= TokenSwap Deployment Finish =============");
}

main();