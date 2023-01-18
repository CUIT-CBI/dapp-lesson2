import { ethers } from "hardhat";

async function main() {
    
    // 获取合约对象
    const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factor");
    const MyUniswapV2Route01 = await ethers.getContractFactory("MyUniswapV2Route01");
    const FT = await ethers.getContractFactory("FT");
    // 部署
    const uniswapV2Factory = await UniswapV2Factory.deploy();
    const myUniswapV2Route01 = await MyUniswapV2Route01.deploy();
    const cbi = await FT.deploy("CUITCBI","CBI");
    const cuit = await FT.deploy("CUIT","cuit");
    // 等待部署完成
    await uniswapV2Factory.deployed();
    await myUniswapV2Route01.deployed();
    await cbi.deployed();
    await cuit.deployed();

    console.log(`new UniswapV2Factory deployed to ${uniswapV2Factory.address}`);
    console.log(`new myUniswapV2Route01 deployed to ${myUniswapV2Route01.address}`);
    console.log(`new cbi deployed to ${cbi.address}`);
    console.log(`new cuit deployed to ${cuit.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
