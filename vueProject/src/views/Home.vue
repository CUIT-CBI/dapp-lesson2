<template>
  <div class="common-layout">
    <el-container class="container">
      <el-header class="header">Header</el-header>
      <el-container>
        <el-aside width="18%" class="aside">
          <el-menu :router="true">
            <el-submenu index="/factory">
              <template #title>
                <i class="el-icon-location"></i>
                <span>用户中心</span>
              </template>
              <el-menu-item index="/factory/add">添加流动性</el-menu-item>
              <el-menu-item index="/factory/remove">移除流动性</el-menu-item>
              <el-menu-item index="/factory/swap">交换代币</el-menu-item>
            </el-submenu>
          </el-menu>
        </el-aside>
        <el-main>
          <!-- 路由占位符 -->
          <router-view></router-view>
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script>
// import HelloWorld from './components/HelloWorld.vue'

export default {
  // name: 'App',
  // components: {
  //   HelloWorld
  // }
}
</script>

<style>
.container {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  height: 100%;
  background-color: rgb(255, 255, 255);
}

.header {
  background-color: rgb(255, 255, 255);
}

.aside {
  background-color: rgb(84, 92, 100);
}
</style>
