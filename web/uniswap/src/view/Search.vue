<template>
  <div>
    <el-button @click="getSwapHistory">查询交易历史</el-button>
    <el-table :data="swapHistory" v-loading="loading">
      <el-table-column prop="customer" label="客户地址"></el-table-column>
      <el-table-column prop="tokenType" label="交易的token类型"></el-table-column>
      <el-table-column prop="tokenNumber" label="交易的token数量"></el-table-column>
    </el-table>
  </div>
</template>


<script>
import Web3 from 'web3';
// 配置Web3对象
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

export default {
  name:"Search",
  data() {
    return {
      swapHistory: [],
      loading: false
    }
  },
  methods: {
    async getSwapHistory() {
      try {
        this.loading = true;
        // 调用getPastEvents方法获取交易历史
        const events = await Store.getPastEvents('swapEvent', {
          fromBlock: 0,
          toBlock: 'latest'
        });
        this.swapHistory = events.map(event => {
          return {
            customer: event.returnValues.customer,
            tokenType: event.returnValues.tokenType,
            tokenNumber: event.returnValues.tokenNumber
          }
        });
      } catch (err) {
        console.log(err);
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>

