import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";

async function main() {
  const FT = await ethers.getContractFactory("FT");
  const ft = await FT.deploy("WangZheng-ERC20", "WZ-ERC20");

  //await ft.deployed();
  //console.log(`FT deployed to ${ft.address}`);

  //5.部署myExchange合约:
  const Exchange = await ethers.getContractFactory("Exchange");
  const myExchange = await Exchange.deploy(ft.address);

  await myExchange.deployed();

  console.log(`myExchange deployed to ${myExchange.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
