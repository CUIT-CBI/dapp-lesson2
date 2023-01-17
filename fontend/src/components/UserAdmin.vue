<template>
  <div>
    <el-form label-width="120px">
      <el-form-item label="Uid">
        <el-input id="uid" v-model="uid"/>
      </el-form-item>
      <el-form-item label="User address">
        <el-input id="address" v-model="address"/>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onSubmit" id="add">Create</el-button>
        <el-button>Cancel</el-button>
      </el-form-item>
    </el-form>
    {{txReceipt}}
  </div>
</template>

<script>
const Web3 = require('web3')

export default {

  data() {
    return {
      uid: '', //2c4ebce0
      address: '', 
      txReceipt:[]
    }
  },

  methods: {
async uuid() {
  return 'xxxxyxxx'.replace(/[xy]/g, function (c) {
    const r = Math.random() * 16 | 0
    const v = c == 'x' ? r : (r & 0x3 | 0x8)
    return v.toString(16)
  })
},

    async onSubmit() {
      if (typeof window.ethereum !== 'undefined') {
  console.log('Ethereum Provider is existed!')
  if (window.ethereum.isMetaMask) {
    console.log('This is MetaMask!')
  }
}
      console.log(typeof(this.copyrightdata))
      console.log(typeof(this.uid))
      const Web3 = require('web3')
      window.addEventListener('load', function() {

  // 检查web3是否已经注入到(Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    // 使用 Mist/MetaMask 的提供者
    web3js = new Web3(web3.currentProvider);
  } else {
    // 处理用户没安装的情况， 比如显示一个消息
    // 告诉他们要安装 MetaMask 来使用我们的应用
  }

  // 现在你可以启动你的应用并自由访问 Web3.js:
  startApp()

})

async function login(){
    if (typeof window.ethereum !== 'undefined') {
        let addr=await ethereum.request({ method: 'eth_requestAccounts' });//授权连接钱包
        console.log('用户钱包地址:',addr[0]);
    }else{
        console.log('未安装钱包插件！');
    }
}
login();

//监听钱包切换
ethereum.on("accountsChanged", function(accounts) {
  console.log('钱包切换')
  window.location.reload();
});
//监听链网络改变
ethereum.on("chainChanged",()=>{
  console.log('链切换')
  window.location.reload();
});
      if(window.web3) {
      const accounts = await ethereum.request({ method: 'eth_requestAccounts' })
      // const web3 = new Web3(new Web3.providers.HttpProvider('https://matic-mumbai.chainstacklabs.com'))
      const web3 = new Web3(window.ethereum)
      const ABI = require('../util/copyright.json')
      const contractAddress = '0x90A9a53Db94F58a2F3a603b48e32434F8Ce359c4'
      const copyright = new web3.eth.Contract(ABI, contractAddress)

const account = accounts[0]
web3.eth.defaultAccount = accounts[0];
console.log(account)
console.log(ethereum.selectedAddress)
this.uid = await this.uuid()

  const transactionParameters = {
    from: ethereum.selectedAddress,
    to: contractAddress,
    data: copyright.methods.addUser(this.uid,this.address).encodeABI(),
    // chainId: '0x80001',
    gas: '0x57e40',
    value: '0x0' 
    // gasPrice:'0x09184e72a000',
  };
  await ethereum.request({
    method: 'eth_sendTransaction',
    params: [transactionParameters],
  })
  .then((txHash) => this.txReceipt=txHash)
    .catch((error) => console.error);
  };
  console.log(this.txReceipt)
  console.log("uid=",this.uid)
  console.log("add=",this.address)
    }
  }
};

</script>

<style lang="scss" scoped></style>