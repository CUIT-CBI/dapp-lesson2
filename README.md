# Sample Hardhat Protocol

## install dependencies
```
yarn
```

## compile contracts
```
yarn compile
```

## start a local node
```
yarn localnode
```

## deploy contracts
modify ```hardhat.config.ts``` and run
```
yarn deploy
```

for examples:
```
heco_testnet: {
    url: "https://http-testnet.hecochain.com",
    chainId: 256,
    accounts: ["0x..."]
},
```

## test contracts
```
yarn test
```

# 完成的功能

1. 增加/移出流动性

   发放LP Token，移除流动性时按比例发放奖励

2. 交易功能

3. 实现手续费功能，千分之三手续费

4. 实现滑点功能

5. 实现部署脚本

## 测试

![image-20230118205956921](README/image-20230118205956921.png)

## 部署

![image-20230118205928297](README/image-20230118205928297.png)

# 加分项-前端功能演示

## 添加流动性

![image-20230118143651481](README/image-20230118143651481.png)

## 移除流动性

![image-20230118143735339](README/image-20230118143735339.png)

## 交换

![image-20230118205334517](README/image-20230118205334517.png)