const { ethers } = require("hardhat");

async function main() {
  // 获得将要部署的合约
  const Token1 = await ethers.getContractFactory("FT");
  const token1 = await Token1.deploy("lyj","TS");
  
  const Token2 = await ethers.getContractFactory("FT");
  const token2 = await Token2.deploy("jyl",'ST');
  
  const ExchangePool = await ethers.getContractFactory("uniswap");
  const exchangepool = await ExchangePool.deploy(token1.address,token2.address);
  console.log("uniswap has deployed:",exchangepool.address)
  console.log("Token1 and Token2 deployed to:", token1.address,token2.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });