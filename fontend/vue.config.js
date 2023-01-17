const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  transpileDependencies: true
})

const AutoImport = require('unplugin-auto-import/webpack')
const Components = require('unplugin-vue-components/webpack')
const { ElementPlusResolver } = require('unplugin-vue-components/resolvers')
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')

module.exports = {
  lintOnSave: false, // 关闭语法检查
  configureWebpack: {
    plugins: [
      AutoImport({
        resolvers: [ElementPlusResolver()]
      }),
      Components({
        resolvers: [ElementPlusResolver()]
      }),
      new NodePolyfillPlugin()
    ],
    // externals: {
    //   fs: require('fs')
    //  }
    // resolve: {
    //   fallback:{
    //     fs: false
    //   }
    // },
    // externals: {
    //   './cptable': 'var cptable',
    // },
  },
  
  // defineConfig:{
  //     transpileDependencies: true
  //   })
}
