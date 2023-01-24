<template>
  <div>
    <el-form>
      <el-form-item>
        <el-input v-model="token" placeholder="请输入代币名称"></el-input>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="getPriceHistory">查询行情</el-button>
      </el-form-item>
    </el-form>
    <el-card>
      <canvas ref="chart" width="600" height="400"></canvas>
    </el-card>
  </div>
</template>


<script>
//import axios from 'axios'
//import Chart from 'chart.js'

export default {
  name:"Market",
  data() {
    return {
      token: ''
    }
  },
  mounted() {
    this.chart = new Chart(this.$refs.chart, {
      type: 'line',
      data: {
        labels: [],
        datasets: [{
          label: 'Price',
          data: [],
          backgroundColor: 'rgba(255, 99, 132, 0.2)',
          borderColor: 'rgba(255, 99, 132, 1)'
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    })
  },
  methods: {
    async getPriceHistory() {
      try {
        const res = await axios.get(`https://api.coingecko.com/api/v3/coins/${this.token}/market_chart`, {
          params: {
            vs_currency: 'usd',
            days: '365'
          }
        })
        const data = res.data.prices.map(item => item[1])
        this.chart.data.datasets[0].data = data
        this.chart.update()
      } catch (err) {
        console.log('获取行情失败', err)
      }
    }
  }
}
</script>

