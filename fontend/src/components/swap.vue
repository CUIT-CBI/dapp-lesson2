<template>
  <div style="margin: 20px">
    <el-form
      label-width="200px"
      :model="swapForm"
      label-position="top"
      ref="swapForm"
    >
      <el-form-item label="WhichSwap">
        <el-select
          v-model="swapForm.function"
          placeholder="please choose your swap function"
        >
          <el-option label="Token1ForToken2" value="Token1ForToken2" />
          <el-option label="Token2ForToken1" value="Token2ForToken1" />
        </el-select>
      </el-form-item>
      <el-form-item label="Address">
        <el-input id="token" v-model="swapForm.token" />
      </el-form-item>
      <el-form-item label="Your Tokens">
        <el-input id="amountTokens" v-model="swapForm.amountTokens" />
      </el-form-item>
      <el-form-item label="Your MaxPrice">
        <el-input id="maxPriceTolerated" v-model="swapForm.maxPriceTolerated" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onSubmit" id="add">Exchange</el-button>
        <el-button @click="resetForm">重置页面</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script>
const Web3 = require("web3");
import SparkMD5 from "spark-md5";
import { reactive, ref } from "vue";
import addjs from "../util/Web3.js";


export default {
  data() {
    return {
      swapdata: [
        "swapTokensForETH",
        "0xbf46569866dF20a7847477bE1d1B78064a6dcF94",
        "1",
        "10000000000000000000000",
      ],
      txReceipt: [],
      swapForm: {
        function: "swapTokensForETH",
        token: "0xbf46569866dF20a7847477bE1d1B78064a6dcF94",
        amountTokens: "1",
        maxPriceTolerated: "100000000000000000000000",
      },
      addLiquidityData: [],
    };
  },

  methods: {
    resetForm() {
      this.swapForm = this.$options.data().swapForm
    },

    async onSubmit() {

      if (typeof window.ethereum !== "undefined") {
        console.log("Ethereum Provider is existed!");
        if (window.ethereum.isMetaMask) {
          console.log("This is MetaMask!");
        }
      }
      const Web3 = require("web3");
      window.addEventListener("load", function () {
        if (typeof web3 !== "undefined") {
          web3js = new Web3(web3.currentProvider);
        } else {
        }
        startApp();
      });

      async function login() {
        if (typeof window.ethereum !== "undefined") {
          let addr = await ethereum.request({ method: "eth_requestAccounts" }); //授权连接钱包
          console.log("用户钱包地址:", addr[0]);
        } else {
          console.log("未安装钱包插件！");
        }
      }
      login();

      //监听钱包切换
      ethereum.on("accountsChanged", function (accounts) {
        console.log("钱包切换");
        window.location.reload();
      });
      //监听链网络改变
      ethereum.on("chainChanged", () => {
        console.log("链切换");
        window.location.reload();
      });
      if (window.web3) {
        const accounts = await ethereum.request({
          method: "eth_requestAccounts",
        });
        const web3 = new Web3(window.ethereum);
        const ABI = require("../util/copyright.json");
        const contractAddress = "0xc76450e76149967723b29069D2FfC58c5D855236";
        const factory = new web3.eth.Contract(ABI, contractAddress);
        console.log(factory);

        console.log(ethereum.selectedAddress); // 还未申请授权，值为null
        const account = accounts[0];
        web3.eth.defaultAccount = accounts[0];
        const add = await web3.eth.accounts[0];
        console.log(add);
        console.log(ethereum.selectedAddress);
        let transactionParameters;
        if (this.swapForm.function == "swapTokensForETH") {
          transactionParameters = {
            from: ethereum.selectedAddress,
            to: contractAddress,
            data: factory.methods
              .swapTokensForETH(this.swapForm.token, this.swapForm.amountTokens, this.swapForm.maxPriceTolerated)
              .encodeABI(),
            gas: "0x6ddd0",
            value: "0x0",
          };
        } else if (this.swapForm.function == "swapETHForTokens") {
          transactionParameters = {
            from: ethereum.selectedAddress,
            to: contractAddress,
            data: factory.methods
              .swapTokensForETH(this.swapForm.token, this.swapForm.maxPriceTolerated)
              .encodeABI(),
            gas: "0x6ddd0",
            value: "0x0",
          };
        }
        await ethereum
          .request({
            method: "eth_sendTransaction",
            params: [transactionParameters],
          })
          .then((txHash) => (this.txReceipt = txHash))
          .catch((error) => console.error);
      }
      console.log(this.txReceipt);
    },
  },
};

</script>

<style lang="scss" scoped></style>
