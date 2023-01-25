// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
require("hardhat");

// options which are provided for user
const autoCreateDefaultAMM=true;
//if the autoCreateDefaultAMM is true ,it can be createdby system
let optionalAMM;

let TransactionMarket;

async function main() {
  //deploy Factory contract
  const store_pool = await ethers.getContractFactory("storeFactory");
  TransactionMarket = await store_pool.deploy();
  await TransactionMarket.deployed();
  console.log("--------------------Congratulations you create transaction market successfully！！-------------------")
  console.log(" Contract address is：     ",TransactionMarket.address)
  console.log("--------------------------------------------------------------------------------------------------")
  //deploy two token if user need 
  if(autoCreateDefaultAMM){
  let ERC20Facotry = await ethers.getContractFactory("FT");
  ERC20A = await ERC20Facotry.deploy("tokenA", "xyA");
  ERC20B = await ERC20Facotry.deploy("tokenB", "xyB");
  await ERC20A.deployed();
  await ERC20B.deployed();
  //create store contract through store factory
  await TransactionMarket.createStore(ERC20A.address, ERC20B.address);
  optionalAMM = await TransactionMarket.searchAMM(ERC20A.address, ERC20B.address);
  console.log("---------------------creating default AMM successfully--------------------------------------------");
  console.log("Support transaction currency address is:",ERC20A.address,"  ",ERC20B.address);
  console.log("AMM address is:",optionalAMM)
  console.log("--------------------------------------------------------------------------------------------------")


  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
