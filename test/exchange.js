const { expect } = require("chai");

describe("add liquidity", function () {
    let token, exchange;
    beforeEach(async () =>{
        const total = ethers.utils.parseEther('21000000')
        const Token = await ethers.getContractFactory("FT");
        token = await Token.deploy("WrappedETC", "WETH", total);
        
        const Exchange = await ethers.getContractFactory("Exchange");
        exchange = await Exchange.deploy(token.address);
        await token.approve(exchange.address, '200');
        
        const tokenamount = ethers.utils.parseEther('200');
        const ethamount = ethers.utils.parseEther('100');
        await Exchange.addLiquidity(tokenamount, {value: ethamount});
        
        expect(await exchange.getReserve()).to.equal(tokenamount);
        

    })

    describe("get token amount", async function () {
        it("return valid token amount", async function () {
            const tokenOut = await exchange.getTokenAmount(ethers.utils.parseEther('100'))
            console.log(ethers.utils.formatEther(tokenOut));
        });

        it("return valid eth amount", async function () {
            const ethOut = await exchange.getEthAmount(ethers.utils.parseEther('100'))
            console.log(ethers.utils.formatEther(ethOut));
        });
       
    });
});
