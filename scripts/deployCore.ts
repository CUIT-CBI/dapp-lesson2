import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

//部署core合约
async function main() {
  console.log("deploy starting");
  const coreFactory = await ethers.getContractFactory('uniswapCore');
  const core = await coreFactory.deploy('LDN','LD');
  await core.deployed();
  console.log(`core has been deployed to ${core.address}`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
