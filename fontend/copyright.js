const Web3 = require('web3')
const ABI = require('./copyright.json')
const contractAddress = '0xE90CDF6e6C049527dc6579587471F011E07AD1A4'
const address = '0x80ec8696D724686adCC88fFF14Bde24A4d0e38De'
const privateKey = 'ce4bd15a4c479a148c701b6e4019f39b23bf90b9803ef8d441e691f66ce0ae05'
const web3 = new Web3(new Web3.providers.HttpProvider('https://matic-mumbai.chainstacklabs.com'))

const path = require('path')
const fs = require('fs')
const crypto = require('crypto')

// 添加账户
web3.eth.accounts.wallet.add(privateKey)

console.log('test')
web3.eth.net.isListening().then(console.log)

// 测试是否连接成功
// web3.eth.getBlock(0, function(error, result){
//     if(!error)
//         console.log(result)
//     else
//         console.log("something wrong,the connection might be failed");
//     console.error(error);
// })

// 通过ABI和地址获取已部署的合约对象
const copyright = new web3.eth.Contract(ABI, contractAddress)// 新的api
if (!copyright) {
  console.log('no contract instance build')
}

async function md5DataFinger(fileName) {
  const stream = fs.createReadStream(path.join(__dirname, fileName))
  const buffer = fs.readFileSync(path.join(__dirname, fileName))
  const hash = crypto.createHash('md5')
  // 大文件
  // stream.on('data', chunk => {
  //     hash.update(chunk, 'utf8');
  // });
  // stream.on('end', async function() {
  //     const md5 = await hash.digest('hex');
  //     console.log("dataFinger =",md5);
  //     return md5
  // });
  hash.update(buffer, 'utf8')
  const md5 = hash.digest('hex')
  console.log('dataFinger =', md5)
  return md5
}

// 版权存证号。规则为uid+当前时间戳+4位随机数
function setKey(uid) {
  const timestamp = new Date().getTime()
  const randomNum = Math.floor(Math.random() * 9000)
  console.log('key =', (uid + timestamp + randomNum))
  return (uid + timestamp + randomNum)
}

function uuid() {
  return 'xxxxyxxx'.replace(/[xy]/g, function (c) {
    const r = Math.random() * 16 | 0
    const v = c == 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
}

async function query(key) {
  const copyrightQuery = await copyright.methods.copyrightQuery(key).call()
  console.log('query =', copyrightQuery)
}

async function getsign(data) {
  const TheSigndata = await copyright.methods.getTheSigndata(
    data
  ).call()
  console.log('TheSigndata =', TheSigndata.toString())
  // await web3.eth.personal.unlockAccount(address, privateKey, 600)
  const sign = await web3.eth.sign(TheSigndata, address)
  console.log('sign =', sign)
  return sign
}

async function addUser(Uid, addr) {
  const functionEncode = await copyright.methods.addUser(Uid, addr).encodeABI()
  const sign = await web3.eth.accounts.signTransaction({
    gas: 300000,
    to: contractAddress,
    data: functionEncode
  }, privateKey)
  const result = await web3.eth.sendSignedTransaction(sign.rawTransaction)
  console.log('addUser txHash =', result.transactionHash)
}

async function addCopyright(data, uid) {
  const theSign = await getsign(data)
  const functionEncode = await copyright.methods.copyrightAdd(
    data,
    uid,
    theSign
  ).encodeABI()
  const sign = await web3.eth.accounts.signTransaction({
    gas: 500000,
    to: contractAddress,
    data: functionEncode
  }, privateKey)
  const result = await web3.eth.sendSignedTransaction(sign.rawTransaction)
  console.log('addCopyright txHash =', result.transactionHash)
}

async function updateCopyright(data, uid) {
  const theSign = await getsign(data)
  const functionEncode = await copyright.methods.copyrightUpdate(
    data,
    uid,
    theSign
  ).encodeABI()
  const sign = await web3.eth.accounts.signTransaction({
    gas: 500000,
    to: contractAddress,
    data: functionEncode
  }, privateKey)
  const result = await web3.eth.sendSignedTransaction(sign.rawTransaction)
  console.log('updateCopyright txHash =', result.transactionHash)
}

async function main() {
  const uid1 = uuid()
  console.log('uid =', uid1)
  const dataFinger = await md5DataFinger('1.txt')
  const key = setKey(uid1)
  const data = [key, 'a', dataFinger, 1, 1, 1, 1, 1, 'Alice', '0x086816ED0dF2B68e292fcD67B852dd97B92f059D', 1, 'http', 1, 'office', 1, 'more']
  await query(key)
  await addUser(uid1, '0x80ec8696D724686adCC88fFF14Bde24A4d0e38De')
  await addCopyright(data, uid1)
  // let newData = ["123","a","124",2,1,1,1,1,"Alice",'0x086816ED0dF2B68e292fcD67B852dd97B92f059D',1,"http",1,"office",1,"more"]
  // await updateCopyright(newData,"1")
  await query(key)
}

// main()

// key: 'c4e38a5416583001998553590'
// dataFinger: 'db1a1e9dd00f696b90fa3b2125d48b40'
// uid:c4e38a54

// query('123')
// console.log(typeof(["123","a","124",2,1,1,1,1,"Alice",'0x086816ED0dF2B68e292fcD67B852dd97B92f059D',1,"http",1,"office",1,"more"]))

getsign(["123123","a","1245",2,1,1,1,1,"Alice",'0x086816ED0dF2B68e292fcD67B852dd97B92f059D',1,"http",1,"office",1,"more"])
