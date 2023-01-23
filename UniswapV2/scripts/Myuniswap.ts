async function main() {
    const FT = await ethers.getContractFactory("FT");
    const ft = await FT.deploy("CBI", "CUIT");
  
    await ft.deployed();
    const tokenA = await FT.deploy("tokenA", "DXPA");
    await tokenA.deployed();
    const tokenB = await FT.deploy("tokenB", "DXPB");
    await tokenB.deployed();
    const Pair = await FT.deploy(ft.address, tokenA.address, tokenB.address);
    await Pair.deployed();
    console.log(`FT deployed to ${ft.address}`);
    console.log(`tokenA deployed to ${tokenA.address}`);
    console.log(`tokenB deployed to ${tokenB.address}`);
    console.log(`Pair deployed to ${Pair.address}`);
  }