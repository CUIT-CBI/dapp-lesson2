import { ethers } from "hardhat";

async function main() {
    console.log("============= StakePool Deployment Start =============");

    const RewardToken_Factory = await ethers.getContractFactory('RewardToken');
    const RewardToken = await RewardToken_Factory.deploy();
    await RewardToken.deployed();
    const RewardToken_address = RewardToken.address;
    console.log(`RewardToken has been deployed at ${RewardToken_address}`);

    // 这里填之前所部署的 TokenSwap 的合约地址
    const StakeToken_address = '0x966969F0060ffF83FF9BB23b69762154Ee13182E';

    const StakePool_Factory = await ethers.getContractFactory('StakePool');
    const StakePool = await StakePool_Factory.deploy(RewardToken_address, StakeToken_address);
    await StakePool.deployed();
    console.log(`StakePool has been deployed at ${StakePool.address}`);

    console.log("============= StakePool Deployment Finish =============");
}

main();