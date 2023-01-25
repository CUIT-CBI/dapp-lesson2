const {expect}=require("chai");
const {ether, ethers}=require("hardhat");

describe("Token",function(){
let Token, token, owner, addr1,addr2

beforeEach(async()=>{
Token=await ethers.getContractFactory('Lock');
token=await Token.deploy();
 //使用 ethers.getSigners() 
 //来获取所有配置的帐户并打印它们的每个地址。
[owner,addr1,addr2]=await ethers.getSigners();
})
describe('test Deployment',()=>{
it('所有者正确',async()=>{
expect(await token.owner()).to.equal(owner.address);
})
it('部署者拥有所有的通证',async()=>{
const totalsupply =await token.totalSupply()
 expect(await token.balancesOf(owner.address)).to.equal(totalsupply);
})
})
describe('发送token',()=>{
    it('正确发送token ' , async()=>{
    await token.transfer(addr1.address, 100);
    let balAddr1= await token.balancesOf(addr1.address);
    console.log( balAddr1);
    console.log( balAddr1==99);
    expect(balAddr1).to.equal( 99);

    await token.connect(addr1).transfer(addr2.address,50);
    let balAddr2=await token.balancesOf(addr2.address);
    expect(balAddr2).to.equal(49);
})
})

})