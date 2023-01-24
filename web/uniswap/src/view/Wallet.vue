<template>
  <div>
    <el-form>
      <el-form-item>
        <el-input v-model="privateKey" placeholder="请输入私钥"></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="importAccount">导入账户</el-button>
      </el-form-item>
    </el-form>

    <el-card>
      <p>当前账户余额：{{ balance }} ETH</p>
    </el-card>

    <div>
      <el-card class="box-card">
        <div slot="header" class="clearfix">
          <span>My Wallet</span>
        </div>
        <el-form ref="form" :model="form" label-width="120px">

          <el-form-item label="Address">
            <el-input v-model="form.address" disabled></el-input>
          </el-form-item>
          <el-form-item label="Token0 Balance">
            <el-input v-model="form.token0Balance" disabled></el-input>
          </el-form-item>
          <el-form-item label="Token1 Balance">
            <el-input v-model="form.token1Balance" disabled></el-input>
          </el-form-item>
        </el-form>
      </el-card>
    </div>
  </div>

</template>


<script>
import Web3 from 'web3';
// 配置Web3对象
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

export default {
  name:"Wallet",
  data() {
    return {
      privateKey: '',
      address: '',
      balance: 0,
      form: {
        address: '',
        token0Balance: '',
        token1Balance: ''
      }
    }
  },
  methods: {
    async importAccount() {
      try {
        const account = web3.eth.accounts.privateKeyToAccount(this.privateKey)
        this.address = account.address
        this.balance = await web3.eth.getBalance(account.address)
      } catch (err) {
        console.log('导入账户失败', err)
      }
    }
  },
  mounted() {
    this.form.address = web3.eth.defaultAccount
    Store.methods.balanceOf(web3.eth.defaultAccount).call()
      .then((balance) => {
        this.form.token0Balance = balance
      })
    Store.methods.balanceOf(web3.eth.defaultAccount, 'token1').call()
      .then((balance) => {
        this.form.token1Balance = balance
      })
  }
}
</script>

