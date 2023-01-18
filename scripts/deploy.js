 const ethers = require('ethers');
const { expect } = require("chai");
const fs = require('fs');
const abi1 =[
  "constructor(string memory name, string memory symbol)",
  "function mint(address account, uint256 amount) external onlyOwner",
  "function burn(uint256 amount) external",
  "function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused",
  "function pause() external onlyOwner",
  "function unpause() external onlyOwner"
];
const maticvigil = 'https://rpc-mumbai.maticvigil.com/';
const FT = fs.readFileSync('./Ft.bytes.txt');
const bytecode1 = FT.toString();
let tokenaddress1;
let tokenaddress2;

const providermaticvigil = new ethers.providers.JsonRpcProvider(maticvigil);
const privatekey = '0xde371647ea53072599148acec702e343a6fbc323245fb747bc200994eb7d5b05';
const wallet = new ethers.Wallet(privatekey.toString(), providermaticvigil);

async function main()
 {                                                                                                
  let token1 = new ethers.ContractFactory(abi1,bytecode1,wallet);
  let token2 = new ethers.ContractFactory(abi1,bytecode1,wallet);
  let tcontract = await token1.deploy('uncle','UC');
  let t2contract = await token2.deploy('zhuang','ZYZ');
  tokenaddress1=tcontract.address;
  tokenaddress2=t2contract.address;
  console.log(tcontract.address,t2contract.address);
  await tcontract.deployed();
  await t2contract.deployed();
 let abi2 = [ 
  "constructor(address _token1Address,address _token2Address)",
  "function addLiquidity(uint256 _amount1,uint256 _amount2)public  returns(uint256)",
  "function removeLiquidity(uint256 liquidity)public returns(uint256,uint256)",
  "function getReserve() public view returns (uint256,uint256)",
  "function  getAmount(uint256 inputAmount,uint256 inputReserve, uint256 outputReserve)private pure returns(uint256)",
  "function  getToken1Amount(uint256 _token1Sold)public view returns(uint256)",
  "function getEtherAmount(uint256 _token2Sold)public view returns(uint256)",
  "function  token2ToToken1Swap(uint256 _token2Sold)public  returns(uint256)",
  "function Token1ToToken2Swap(uint256 _token1Sold)public",
  "function  CaculateToken1Slippage(uint256 _token1Sold)public view returns(uint256)",
  "function  CaculateToken2Slippage(uint256 _token2Sold)public view returns(uint256)",
  "function min(uint256 a ,uint256 b)public pure returns(uint256)"
 ];
 const unswapbytecode2 = fs.readFileSync('./Unswap.bytes.txt');

 const bytecode2 = unswapbytecode2.toString();

 ( async function(){
  const factory = new ethers.ContractFactory(abi2,bytecode2,wallet)
  const contract = await factory.deploy(tokenaddress1,tokenaddress2);
  console.log(contract.address);
  await contract.deployed()
  })();
};
main();
