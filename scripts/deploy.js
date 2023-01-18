//  const ethers = require('ethers');
// const { expect } = require("chai");
// const fs = require('fs');
// const abi1 =[
//   "constructor(string memory name, string memory symbol)",
//   "function mint(address account, uint256 amount) external onlyOwner",
//   "function burn(uint256 amount) external",
//   "function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused",
//   "function pause() external onlyOwner",
//   "function unpause() external onlyOwner"
// ];
// const Georli = 'https://eth-goerli.g.alchemy.com/v2/GeRIcQ0nWlQWwS3tR0D1xsDfqkjNRBYu';
// const readbytecode = fs.readFileSync('./tokenbytecode.txt');

// const bytecode1 = readbytecode.toString();
// const providerGeorli = new ethers.providers.JsonRpcProvider(Georli);
// const privatekey = '1fb938cda49a27b3551652c195c80b5963930e41bacceae38723ad66ddb42046';
// const wallet = new ethers.Wallet(privatekey.toString(), providerGeorli);
// let tokenaddress1;
// let tokenaddress2;
// async function main() {                                                                                                
//   let factory1 = new ethers.ContractFactory(abi1,bytecode1,wallet);
//   let factory2 = new ethers.ContractFactory(abi1,bytecode1,wallet);
//   // const total = ethers.utils.parseEther('21000000');
//   let mcontract = await factory1.deploy('dyx','dfy');
//   let mcontract1 = await factory2.deploy('xyd','yfd');
//   tokenaddress1=mcontract.address;
//   tokenaddress2=mcontract1.address;
//   console.log(mcontract.address,mcontract1.address);
//   console.log( mcontract.deployTransaction.hash,mcontract1.deployTransaction.hash);
//   await mcontract.deployed();
//   await mcontract1.deployed();
// let abi2 = [ 
//   "constructor(address _token1Address,address _token2Address)",
//   "function addLiquidity(uint256 _amount1,uint256 _amount2)public  returns(uint256)",
//   "function removeLiquidity(uint256 liquidity)public returns(uint256,uint256)",
//   "function getReserve() public view returns (uint256,uint256)",
//   "function  getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256)",
//   "function  getToken1Amount(uint256 _token1Sold)public view returns(uint256)",
//   "function getEtherAmount(uint256 _token2Sold)public view returns(uint256)",
//   "function  token2ToToken1Swap(uint256 _token2Sold)public  returns(uint256)",
//   "function Token1ToToken2Swap(uint256 _token1Sold)public",
//   "function  CaculateToken1Slippage(uint256 _token1Sold)public view returns(uint256)",
//   "function  CaculateToken2Slippage(uint256 _token2Sold)public view returns(uint256)",
//   "function min(uint256 a ,uint256 b)public pure returns(uint256)"
// ];
// const readbytecode2 = fs.readFileSync('./exchangebytecode.txt');

// const bytecode2 = readbytecode2.toString();

// (async function(){
//   const factory2 = new ethers.ContractFactory(abi2,bytecode2,wallet)
//   const contract = await factory2.deploy(tokenaddress1,tokenaddress2);
//   console.log(contract.address);
//   console.log( contract.deployTransaction.hash);
//   await contract.deployed()
//   })();
// };
// main();
