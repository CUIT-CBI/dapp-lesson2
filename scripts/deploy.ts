import '@nomiclabs/hardhat-ethers';
import { ethers } from "hardhat";
// yarn localnode

// Owner of contracts is :          0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199
// ****** deploy contracts ******
// TokenA deployed in :             0xeFe507e8B675F79DB622d743572cF43be5a5F9A4
// TokenB deployed in :             0x1c3C83372648cf9E57e1744D68D620262544B59F
// Uniswap deployed in :            0x685Ba83708e2355C2CDE6BfD6DD16702ce0B775A
// ****** addLiquidity ******
// TokenA in pool is :              100000
// TokenB in pool is :              100000
// The K is :                       10000000000
// TokenA liquidity of owner is :   99700
// TokenB liquidity of owner is :   99700
// ****** swapExactAforB ******
// TokenA in pool is :              200000
// TokenB in pool is :              50075
// Now the K including fee is :     10015000000
// Done in 3.78s.

async function main() {
    // const FT = await ethers.getContractFactory('FT');
    // const ft = await FT.deploy('CBI', 'CUIT');

    // await ft.deployed();
    // console.log(`FT deployed to ${ft.address}`);

    let TokenA, ContrcatTokenA, TokenB, ContrcatTokenB, Uniswap, ContrcatUniswap;
    let owner, addr1;;
    let addrA, addrB, addrUniswap, addrOwner;
    TokenA = await ethers.getContractFactory('TokenA');
    ContrcatTokenA = await TokenA.deploy();
    TokenB = await ethers.getContractFactory('TokenB');
    ContrcatTokenB = await TokenB.deploy();
    Uniswap = await ethers.getContractFactory('Uniswap');
    ContrcatUniswap = await Uniswap.deploy(ContrcatTokenA.address, ContrcatTokenB.address);

    [owner, addr1,] = await ethers.getSigners();

    addrA = ContrcatTokenA.address;
    addrB = ContrcatTokenB.address;
    addrUniswap = ContrcatUniswap.address;
    addrOwner = owner.address;

    console.log('Owner of contracts is :\t\t', addrOwner);
    console.log("******", "deploy contracts", "******")
    console.log('TokenA deployed in :\t\t', addrA);
    console.log('TokenB deployed in :\t\t', addrB);
    console.log('Uniswap deployed in :\t\t', addrUniswap);

    let amount = 1000*1000*1000;
    await ContrcatTokenA.approve(addrUniswap, amount);
    await ContrcatTokenB.approve(addrUniswap, amount);
    console.log("******", "addLiquidity", "******");
    await ContrcatUniswap.addLiquidity(100000, 100000);
    let AinPool = await ContrcatUniswap.poolOfA();
    let BinPool = await ContrcatUniswap.poolOfB();
    console.log('TokenA in pool is :\t\t', AinPool.toNumber());
    console.log('TokenB in pool is :\t\t', BinPool.toNumber());
    let k = await ContrcatUniswap.get_k();
    console.log('The K is :\t\t\t', k.toNumber());
    let liq = await ContrcatUniswap.getLiquidity(addrOwner);
    console.log('TokenA liquidity of owner is :\t', liq.liq_a.toNumber());
    console.log('TokenB liquidity of owner is :\t', liq.liq_b.toNumber());
    // await ContrcatUniswap.removeLiquidity(50000, 50000);

    console.log("******", "swapExactAforB", "******");
    await ContrcatUniswap.swapExactAforB(100000);
    let AinPool2 = await ContrcatUniswap.poolOfA();
    let BinPool2 = await ContrcatUniswap.poolOfB();
    console.log('TokenA in pool is :\t\t', AinPool2.toNumber());
    console.log('TokenB in pool is :\t\t', BinPool2.toNumber());
    let k2 = await ContrcatUniswap.get_k();
    console.log('Now the K including fee is :\t', k2.toNumber());

    // let liq2 = await ContrcatUniswap.getLiquidity(addrOwner);
    // console.log('TokenA liquidity of owner is :\t', liq2.liq_a.toNumber());
    // console.log('TokenB liquidity of owner is :\t', liq2.liq_b.toNumber());
}

// 我们推荐这种模式，以便能够在任何地方使用async/await并正确处理错误
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Georli testnet
// const privatKey = '';
// const Georli = 'https://eth-goerli.g.alchemy.com/v2/GeRIcQ0nWlQWwS3tR0D1xsDfqkjNRBYu';
// const providerGeorli = new ethers.providers.JsonRpcProvider(Georli);
// const walletWithProvider = new ethers.Wallet(privatKey, providerGeorli);
// const myAddress = await walletWithProvider.address;
// let myGeorliBalance = await walletWithProvider.getBalance();
// let etherString = ethers.utils.formatEther(myGeorliBalance);
// console.log('钱包地址:', myAddress);
// console.log('钱包余额:', etherString);
