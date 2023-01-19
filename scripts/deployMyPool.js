const hre = require("hardhat");
const {address} = require("hardhat/internal/core/config/config-validation");

async function main(){

    const [signers] = await hre.ethers.getSigners();

    const MySwap  =await hre.ethers.getContractFactory("LooneySwapPool",signers);
    const  mySwap = await MySwap.deploy();

    await mySwap.deployed();
    console.log(mySwap.address);
}
main().catch((error) => {
    console.log(error);
    process.exit(1)
});