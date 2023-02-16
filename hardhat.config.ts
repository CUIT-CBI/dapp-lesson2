import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  defaultNetwork: "localhost",
  networks: {
    hardhat: {},
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"]
    },
    heco_testnet: {
      url: "https://http-testnet.hecochain.com",
      chainId: 256,
    },
    heco_mainnet: {
      url: "https://http-mainnet.hecochain.com",
      chainId: 128,
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};

export default config;
