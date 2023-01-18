import { expect } from "chai";
import hre, {ethers} from "hardhat";

describe("swapFactory", function () {
    it("Should add, swap and remove success", async function () {
        const [owner,Alice] = await ethers.getSigners();

        const Token0 = await hre.ethers.getContractFactory("FT");
        const token0 = await Token0.deploy("token0", "CUIT");

        await token0.deployed();
        console.log(`token0 deployed to ${token0.address}`);

        await token0.mint(Alice.address,10000);
        await token0.mint(owner.address,10000);

        const Token1 = await hre.ethers.getContractFactory("FT");
        const token1 = await Token1.deploy("token1", "CUIT");

        await token1.deployed();
        console.log(`token1 deployed to ${token1.address}`);

        await token1.mint(Alice.address,10000);
        await token1.mint(owner.address,10000);

        const Pair = await hre.ethers.getContractFactory("uniswapV2Pair");
        const pair = await Pair.deploy(token0.address, token1.address);

        await pair.deployed();
        console.log(`pair deployed to ${pair.address}`);

        // await pair.initPair(token0.address, token1.address);

        const Router = await hre.ethers.getContractFactory("uniswapV2Router");
        const router = await Router.deploy(pair.address);

        await router.deployed();
        console.log(`router deployed to ${router.address}`);

        // approve
        await token0.connect(Alice).approve(router.address, 10000);
        await token1.connect(Alice).approve(router.address, 10000);

        await pair.connect(Alice).approve(router.address, 10000);

        await token0.connect(owner).approve(router.address, 10000);
        await token1.connect(owner).approve(router.address, 10000);

        await pair.connect(owner).approve(router.address, 10000);

        await router.connect(owner).addLiquidity(
            token0.address,
            token1.address,
            1000,
            1000,
            999,
            999,
            owner.address
        );

        // 添加流动性
        await router.connect(Alice).addLiquidity(
            token0.address,
            token1.address,
            1000,
            1000,
            999,
            999,
            Alice.address
        );

        expect(await pair.getTokenReserve(token0.address)).to.equal(2000);
        expect(await pair.getTokenReserve(token1.address)).to.equal(2000);
        // LP token totalSupply
        expect(await pair.totalSupply()).to.equal(2000)

        await router.connect(Alice).swapExactTokenForToken(
            100,
            100,
            token0.address,
            token1.address,
            Alice.address,
            10
        )

        // 会扣除千分之三的手续费
        expect(await pair.getTokenReserve(token0.address)).to.equal(2100);
        expect(await pair.getTokenReserve(token1.address)).to.equal(1906);

        // 移除流动性
        await router.connect(Alice).removeLiquidity(
            1000,
            900,
            900,
            Alice.address
        )

        expect(await pair.getTokenReserve(token0.address)).to.equal(1040);
        expect(await pair.getTokenReserve(token1.address)).to.equal(944);

        // 最终收益
        expect(await token0.balanceOf(Alice.address)).to.equal(9960);
        expect(await token1.balanceOf(Alice.address)).to.equal(10056);

    });
});
