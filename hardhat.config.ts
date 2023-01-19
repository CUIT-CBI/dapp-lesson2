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
      accounts: ["0xd2934a4fc985660120d4c8df0591ef7f1206bf4ccb8a876feb4e912a8a331f42", "0x3029e8bcd2933ef0deba9a44000cbb8a6d55ae84470fff43a838facc69736b3c"]
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
