<template>
  <div style="height: 1100px">
    <el-container style="height: 100%; border: 1px solid #eee">
      <el-aside width="200px" style="background-color: rgb(238, 241, 246)">
        <el-menu
          default-active="2"
          class="el-menu-vertical-demo">
          <router-link to="/searchstore">
            <el-menu-item index="1">
              <i class="el-icon-menu"></i>
              <span slot="title">首页</span>
            </el-menu-item>
          </router-link>

          <router-link to="/search">
            <el-menu-item index="2">
              <i class="el-icon-search"></i>
              <span slot="title">历史交易</span>
            </el-menu-item>
          </router-link>

          <router-link to="/wallet">
            <el-menu-item index="3">
              <i class="el-icon-menu"></i>
              <span slot="title">钱包</span>
            </el-menu-item>
          </router-link>

          <router-link to="/market">
            <el-menu-item index="4">
              <i class="el-icon-menu"></i>
              <span slot="title">市场</span>
            </el-menu-item>
          </router-link>

          <router-link to="/trade">
            <el-menu-item index="5">
              <i class="el-icon-menu"></i>
              <span slot="title">交易</span>
            </el-menu-item>
          </router-link>
        </el-menu>
      </el-aside>

      <el-main>
        <router-view />
      </el-main>

    </el-container>
  </div>
</template>

<script>
export default {
  name: "Main"
}
</script>

<style scoped>

</style>
