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