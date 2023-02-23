async function main() {

    const FT = await ethers.getContractFactory("FT");
    const ft = await FT.deploy("CBI", "CUIT");

    const token0 = await FT.deploy("token1", "myl");
    await token0.deployed();
    const token1 = await FT.deploy("token2", "zc");
    await token1.deployed();

    console.log(`token0 deployed to ${token0.address}`);
    console.log(`token1 deployed to ${token1.address}`);

    await ft.deployed();

    console.log(`FT deployed to ${ft.address}`);

    const Pair = await ethers.getContractFactory("pair");
    const pair = await Pair.deploy(token0.address, token1.address);

    await pair.deployed();
    console.log(`Pair deployed to ${pair.address}`);
  }

  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  }
  );
