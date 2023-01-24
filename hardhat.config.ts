import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: 0,
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    sources: "contracts",
  },
  networks: {
    hardhat: {},
    ganache: {
      url: "http://127.0.0.1:7545/",
      saveDeployments: true,
      chainId: 1337,
      live: true,
    },
  },
};

export default config;