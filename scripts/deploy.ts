import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const token1="111";
  const token2="222";
  const tokenpair = await ethers.getContractFactory("TokenPair");
  const TokenPair = await tokenpair.deploy(token1, token2);

  await TokenPair.deployed();
  console.log(`FT deployed to ${TokenPair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
