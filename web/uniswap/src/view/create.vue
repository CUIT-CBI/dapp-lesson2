<template>
  <div>
    <el-button @click="createStore">创建交易</el-button>
    <el-button @click="searchAMM">查询交易</el-button>
  </div>
</template>

<script>
//import web3 from './web3' // 导入 web3 实例
//import storeFactoryABI from './storeFactory.json' // 导入 storeFactory 合约 ABI
//import storeABI from './store.json' // 导入 store 合约 ABI

export default {
  name:"Create",
  methods: {
    async createStore() {
      // 获取 storeFactory 合约对象
      const storeFactory = new web3.eth.Contract(storeFactoryABI.abi, 'storeFactory_contract_address')
      // 调用 createStore 方法
      await storeFactory.methods
        .createStore('token0_address', 'token1_address')
        .send({ from: 'user_address' })
    },
    async searchAMM() {
      // 获取 storeFactory 合约对象
      const storeFactory = new web3.eth.Contract(storeFactoryABI.abi, 'storeFactory_contract_address')
      // 调用 searchAMM 方法
      const storeAddress = await storeFactory.methods
        .searchAMM('token0_address', 'token1_address')
        .call()
      // 获取 store 合约对象
      const store = new web3.eth.Contract(storeABI.abi, storeAddress)
      // 在这里你可以使用 store 合约对象调用其他方法, 比如调用 getStoreInfo() 方法来获取商店信息
      const storeInfo = await store.methods.getStoreInfo().call()

      // 你也可以使用 Element UI 组件来展示商店信息
      this.$message.success(`商店信息: ${storeInfo}`)
    }
  }
}
</script>
