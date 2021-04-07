/* eslint-disable */
require('dotenv').config();

const HDWalletProvider = require('truffle-hdwallet-provider');

const infuraKey = process.env.SUMMA_RELAY_INFURA_KEY;
const mnemonic = process.env.MNEMONIC;


const ropsten = {
  provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${infuraKey}`),
  network_id: 3,
  gas: 5500000,
  confirmations: 2,
  timeoutBlocks: 200
}

module.exports = {
  api_keys: {
    etherscan: process.env.ETHERSCAN_KEY
  },
  plugins: [
    'solidity-coverage',
    'truffle-plugin-verify'
  ],
  networks: {
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01
    },

    ganache: {
      host: "localhost",
      port: 7545,
    },

    ropsten: ropsten,
  },

  compilers: {
    solc: {
      version: "0.5.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};
