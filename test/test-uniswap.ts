import '@nomiclabs/hardhat-ethers';
import { expect } from "chai";
import { ethers } from "hardhat";
// yarn localnode

// Uniswap Test
// test Deployment
//   ✔ TokenA所有者正确
//   ✔ TokenB所有者正确
//   ✔ TokenA部署者拥有所有的token (41ms)
//   ✔ TokenB部署者拥有所有的token
//   ✔ Uniswap初始化的TokenA地址正确
//   ✔ Uniswap初始化的TokenB地址正确
// test Liquidity
//   ✔ 增加流动性正确 (163ms)
//   ✔ 移出流动性正确 (229ms)
// test Swap
//   ✔ TokenA交换TokenB正确 (221ms)
//   ✔ TokenB交换TokenA正确 (224ms)
// 10 passing (3s)
// Done in 5.31s.

async function testUniswap(){
    describe("Uniswap Test", function () {
        let TokenA, ContrcatTokenA, TokenB, ContrcatTokenB, Uniswap, ContrcatUniswap;
        let owner, addr1;;
        let addrA, addrB, addrUniswap, addrOwner;
        beforeEach(async () => {
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
        })
        describe('test Deployment', () =>{
            it('TokenA所有者正确', async () => {
                expect(await ContrcatTokenA.owner()).to.equal(addrOwner);
            })

            it('TokenB所有者正确', async () => {
                expect(await ContrcatTokenB.owner()).to.equal(addrOwner);
            })

            it('TokenA部署者拥有所有的token',async () => {
                let totalSupply = await ContrcatTokenA.totalSupply();
                expect(await ContrcatTokenA.balanceOf(addrOwner)).to.equal(totalSupply);
            })

            it('TokenB部署者拥有所有的token',async () => {
                let totalSupply = await ContrcatTokenB.totalSupply();
                expect(await ContrcatTokenB.balanceOf(addrOwner)).to.equal(totalSupply);
            })

            it('Uniswap初始化的TokenA地址正确',async () => {
                expect(await ContrcatUniswap.getAddrOfA()).to.equal(addrA);
            })

            it('Uniswap初始化的TokenB地址正确',async () => {
                expect(await ContrcatUniswap.getAddrOfB()).to.equal(addrB);
            })  
        })
        describe('test Liquidity', async () => {
            let amount = 1000*1000*1000;
            it('增加流动性正确', async () => {
                await ContrcatTokenA.approve(addrUniswap, amount);
                await ContrcatTokenB.approve(addrUniswap, amount);
                await ContrcatUniswap.addLiquidity(100000, 100000);
                expect(await ContrcatUniswap.get_k()).to.equal(100000*100000);
            })
            it('移出流动性正确', async () => {
                await ContrcatTokenA.approve(addrUniswap, amount);
                await ContrcatTokenB.approve(addrUniswap, amount);
                await ContrcatUniswap.addLiquidity(100000, 100000);
                await ContrcatUniswap.removeLiquidity(50000, 50000);
                expect(await ContrcatUniswap.get_k()).to.equal(2515022500);
            })
        })
        describe('test Swap', async () => {
            let amount = 1000*1000*1000;
            it('TokenA交换TokenB正确', async () => {
                await ContrcatTokenA.approve(addrUniswap, amount);
                await ContrcatTokenB.approve(addrUniswap, amount);
                await ContrcatUniswap.addLiquidity(100000, 100000);
                await ContrcatUniswap.swapExactAforB(100000)
                expect(await ContrcatUniswap.poolOfB()).to.equal(50075);
            })
            it('TokenB交换TokenA正确', async () => {
                await ContrcatTokenA.approve(addrUniswap, amount);
                await ContrcatTokenB.approve(addrUniswap, amount);
                await ContrcatUniswap.addLiquidity(100000, 100000);
                await ContrcatUniswap.swapExactBforA(100000)
                expect(await ContrcatUniswap.poolOfA()).to.equal(50075);
            })
        })
    });
}
testUniswap();

// localhost: {
//     gas: 2100000,
//     gasPrice: 8000000000,
// }
// "noImplicitAny":false,