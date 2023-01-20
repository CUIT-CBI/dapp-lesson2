import '@nomiclabs/hardhat-ethers';
import { Contract } from 'ethers';
import { ethers } from "hardhat";

async function main() {

  let TokenA = await ethers.getContractFactory("FT");
  let ContrcatTokenA = await TokenA.deploy("tokenA","WWZ");
  let TokenB = await ethers.getContractFactory("FT");
  let ContrcatTokenB = await TokenB.deploy("tokenB","WWZ");
  let wwzExchange = await ethers.getContractFactory("FT");
  let ContrcatExchange = await wwzExchange.deploy(ContrcatTokenA.address, ContrcatTokenB.address);

  let addrA = ContrcatTokenA.address;
  let addrB = ContrcatTokenB.address;
  let addrExchange = ContrcatExchange.address;

  console.log('addrTokenA is :', addrA);
  console.log('addrTokenB is :', addrB);
  console.log('addrwwzExchange is :', addrExchange);

}

 
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
