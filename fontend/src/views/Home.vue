<template>
  <div class="common-layout">
    <el-container class="container">
      <el-header class="header" align="center">2020131071</el-header>
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

export default {

}
</script>

<style>
.container {
  background-color:lightblue
}
.header {
  background-color: rgb(205, 255, 255);
  font-size: 50px;
  color: aliceblue;
  background-image:linear-gradient(rgba(0,0,0,0.5),rgba(0,0,0,0.5)), url(https://images.pexels.com/photos/1083822/pexels-photo-1083822.jpeg?cs=srgb&dl=pexels-lisa-1083822.jpg&fm=jpg);
  background-size: cover;
  background-position: center;
}
.aside {
  background-color:rgb(255, 255, 255);
  background-image: url("../../public/cuit.ico");
  height: 500px;
}
</style>
