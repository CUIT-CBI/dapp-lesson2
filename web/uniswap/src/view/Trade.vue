<template>
  <div>
    <el-input v-model="token0Input" placeholder="请输入token0数量"></el-input>
    <el-input v-model="token1Input" placeholder="请输入token1数量"></el-input>
    <el-button @click="exchange">交易</el-button>
    <p>交易结果: {{result}}</p>
  </div>
</template>


<script>
import Web3 from 'web3';
// 配置Web3对象
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

export default {
  name:"Trade",
  data() {
    return {
      token0Input: '',
      token1Input: '',
      result: ''
    }
  },
  methods: {
    async exchange() {
      try {
        const accounts = await web3.eth.getAccounts();
        // 调用exchange方法
        const tx = await Store.methods.exchange(this.token0Input, this.token1Input).send({ from: accounts[0] });
        if (tx.status) {
          this.result = '交易成功';
        } else {
          this.result = '交易失败';
        }
      } catch (err) {
        console.log(err);
        this.result = '交易失败';
      }
    }
  }
}
</script>
