const Web3 = require('web3')
const ABI = require('./copyright.json')
const contractAddress = '0xE90CDF6e6C049527dc6579587471F011E07AD1A4'
const address = '0x80ec8696D724686adCC88fFF14Bde24A4d0e38De'
const privateKey = 'ce4bd15a4c479a148c701b6e4019f39b23bf90b9803ef8d441e691f66ce0ae05'
const web3 = new Web3(new Web3.providers.HttpProvider('https://matic-mumbai.chainstacklabs.com'))

// 添加账户
web3.eth.accounts.wallet.add(privateKey)

console.log('test')
web3.eth.net.isListening().then(console.log)

// 通过ABI和地址获取已部署的合约对象
const copyright = new web3.eth.Contract(ABI, contractAddress)// 新的api
if (!copyright) {
  console.log('no contract instance build')
}
