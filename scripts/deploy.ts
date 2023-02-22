import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const token1="11111";
  const token2="22222";

  const PAIR = await ethers.getContractFactory("WSCPair");
  const pair = await PAIR.deploy(token1, token2);

  await pair.deployed();
  console.log(`pair deployed to ${pair.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
