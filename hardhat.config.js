/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const { defaultAccounts } = require("ethereum-waffle");

require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");

let secrets = require("./scripts/secrets.json");

module.exports = {
  solidity: "0.8.12",
  networks: {
    rinkeby: {
      url: secrets.infura_url,
      accounts: [secrets.privatKey],
    },
  },
  etherscan: {
    apiKey: "S3NF6SFCGAA3TH65TYZVN8BHWAS16FMXPI",
  },
};
