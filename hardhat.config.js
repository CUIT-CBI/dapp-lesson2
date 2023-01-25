require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks:{
    CBI:{
      url:'http://210.41.225.34:8502',
      accounts:['a6835a77fa37b4251c73c4dc0864bec7f736a5fe3c0fa35c075ee5c8aadfd160']
    }
  }
};
