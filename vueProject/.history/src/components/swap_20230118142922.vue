<template>
  <div style="margin: 20px">
    <el-form
      label-width="150px"
      :model="swapForm"
      label-position="top"
      ref="swapForm"
    >
      <el-form-item label="tokenIn">
        <el-input id="tokenIn" v-model="swapForm.tokenIn" />
      </el-form-item>
      <el-form-item label="amountIn">
        <el-input id="amountIn" v-model="swapForm.amountIn" />
      </el-form-item>
      <el-form-item label="tokenOut">
        <el-input id="tokenOut" v-model="swapForm.tokenOut" />
      </el-form-item>
      <el-form-item label="amountOutMin">
        <el-input id="amountOutMin" v-model="swapForm.amountOutMin" />
      </el-form-item>
      <el-form-item label="to">
        <el-input id="to" v-model="swapForm.to" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="onSubmit" id="add">交换</el-button>
        <el-button @click="resetForm">重置</el-button>
      </el-form-item>
    </el-form>
    <!-- <p>txReceipt:{{ txReceipt }}</p>
    <p>addLiquidityForm:{{ addLiquidityForm }}</p> -->
  </div>
</template>

<script>
const Web3 = require("web3");


export default {
  data() {
    return {
      swapdata: [
        "0xF012Dde63F0C10832319849f684427641A44abc2",
        "100",
        "0x09870A1863b23044F5cd148764F40CdabC453263",
        "90",
        "0x9DC97146b924263A2c8C7237FbeEAFb6ef60b624"
      ],
      txReceipt: [],
      swapForm: {
        tokenIn: "0xF012Dde63F0C10832319849f684427641A44abc2",
        amountIn: "100",
        tokenOut: "0x09870A1863b23044F5cd148764F40CdabC453263",
        amountOutMin: "90",
        to: "0x9DC97146b924263A2c8C7237FbeEAFb6ef60b624"
      },
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
        // 检查web3是否已经注入到(Mist/MetaMask)
        if (typeof web3 !== "undefined") {
          // 使用 Mist/MetaMask 的提供者
          web3js = new Web3(web3.currentProvider);
        } else {
          // 处理用户没安装的情况， 比如显示一个消息
          // 告诉他们要安装 MetaMask 来使用我们的应用
        }

        // 现在你可以启动你的应用并自由访问 Web3.js:
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
        // const web3 = new Web3(new Web3.providers.HttpProvider('https://matic-mumbai.chainstacklabs.com'))
        const web3 = new Web3(window.ethereum);
        const ABI = require("../util/router.json");
        const contractAddress = "0xB0733B3dA4E99D4A552A92555D34DC6Df6F74b76";
        const factory = new web3.eth.Contract(ABI, contractAddress);
        console.log(factory);

        console.log(ethereum.selectedAddress); // 还未申请授权，值为null
        // const accounts = await ethereum.request({ method: 'eth_requestAccounts' })
        const account = accounts[0];
        web3.eth.defaultAccount = accounts[0];
        const add = await web3.eth.accounts[0];
        console.log(add);
        console.log(ethereum.selectedAddress);
        let transactionParameters;

        transactionParameters = {
          from: ethereum.selectedAddress,
          to: contractAddress,
          data: factory.methods
            .swapExactTokenForToken(
              this.swapForm.amountIn,
              this.swapForm.amountOutMin,
              this.swapForm.tokenIn,
              this.swapForm.tokenOut,
              this.swapForm.to
            )
            .encodeABI(),
          // chainId: '0x80001',
          gas: "0x6ddd0",
          value: "0x0",
          // gasPrice:'0x09184e72a000',
        };

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
