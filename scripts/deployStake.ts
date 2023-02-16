import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

//部署质押合约
async function main() {
    console.log("deploy starting");
    //部署质押代币
    const LPToken = await ethers.getContractFactory("LPToken");
    const lpToken = await LPToken.deploy("LPtoken","LP");
    await lpToken.deployed();
    console.log("lpToken's address is",lpToken.address);

    //部署奖励代币
    const rewardTokens = await ethers.getContractFactory("rewardTokens");
    const rewardtokens = await rewardTokens.deploy("UNISWAP","UNI");
    await rewardtokens.deployed();
    console.log("rewardtokens's address is",rewardtokens.address);
    
    //部署stakeFactory工厂合约
    const stakeFactory = await ethers.getContractFactory("stakingFactory")
    const stakefactroy = await stakeFactory.deploy(`${rewardtokens.address}`,1);
    await stakefactroy.deployed();
    console.log("stakefactory's address is",stakefactroy.address)
    
    const [singer] = await ethers.getSigners();
    //铸造奖励代币
    await rewardtokens.mint(singer.address,2000);
    //将将奖励代币转移到质押工厂合约中
    await rewardtokens.transfer(stakefactroy.address,2000);

    //调用工厂合约deploy函数部署子合约
    await stakefactroy.deployStaking(lpToken.address,2000,60);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
