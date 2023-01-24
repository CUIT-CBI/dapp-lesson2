<template>
  <div>
    <el-button @click="getStoreInfo">查询市场信息</el-button>
    <p>token0数量: {{token0Num}}</p>
    <p>token1数量: {{token1Num}}</p>
    <p>最后更新时间: {{blockTimestrampLast}}</p>
  </div>
</template>

<script>
import Web3 from 'web3';
// 配置Web3对象
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
export default {
  name: "SearchStore",
  data() {
    return {
      token0Num: '',
      token1Num: '',
      blockTimestrampLast: ''
    }
  },
  methods: {
    async getStoreInfo() {
      try {
        // 调用getStoreInfo方法
        const storeInfo = await Store.methods.getStoreInfo().call();
        this.token0Num = storeInfo._token0Num;
        this.token1Num = storeInfo._token1Num;
        this.blockTimestrampLast = storeInfo._blockTimestrampLast;
      } catch (err) {
        console.log(err);
      }
    }
  }
}
</script>

<style scoped>

</style>
