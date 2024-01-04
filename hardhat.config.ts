/* eslint-disable prettier/prettier */
import * as dotenv from 'dotenv'
dotenv.config()

import { HardhatUserConfig } from 'hardhat/types'
import { task } from 'hardhat/config'

// Plugins

import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
// import 'hardhat-abi-exporter'
// import 'hardhat-gas-reporter'
// import 'hardhat-contract-sizer'
import '@openzeppelin/hardhat-upgrades'
import '@typechain/hardhat'

// Networks

interface NetworkConfig {
  network: string
  chainId: number
  gas?: number | 'auto'
  gasPrice?: number | 'auto'
}

const networkConfigs: NetworkConfig[] = [
  { network: 'mainnet', chainId: 1 },
]

function getAccountMnemonic() {
  return process.env.MNEMONIC || ''
}

function getDefaultProviderURL(network: string) {
  return `https://${network}.infura.io/v3/${process.env.INFURA_KEY}`
}

function setupDefaultNetworkProviders(buidlerConfig) {
  for (const netConfig of networkConfigs) {
    buidlerConfig.networks[netConfig.network] = {
      chainId: netConfig.chainId,
      url: getDefaultProviderURL(netConfig.network),
      gas: netConfig.gasPrice || 'auto',
      gasPrice: netConfig.gasPrice || 'auto',
      accounts: {
        mnemonic: getAccountMnemonic(),
      },
    }
  }
}

// Tasks

task('accounts', 'Prints the list of accounts', async (taskArgs, bre) => {
  const accounts = await bre.ethers.getSigners()
  for (const account of accounts) {
    console.log(await account.getAddress())
  }
})

// Config

const config: HardhatUserConfig = {
  paths: {
    sources: './contracts',
    tests: './test',
    artifacts: './build/contracts',
  },
  mocha: {
    timeout: 100000000
  },
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          outputSelection: {
            '*': {
              '*': ['storageLayout'],
            },
          },
        },
      },
    ],
  },
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chainId: 1337,
      loggingEnabled: false,
      gas: 12000000,
      gasPrice: 'auto',
      blockGasLimit: 12000000,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
      },
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      chainId: 1,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/YYZyqE0v2BO7ap26Ie16IWdRWpr2T0Wy',
      accounts: [process.env.PRIVATE_KEY],
    },
    matic: {
      url: 'https://polygon-mainnet.g.alchemy.com/v2/RiEdJAsZdbKF1nIOcrNerAF1YgEOVfbR',
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc: {
      url: 'https://data-seed-prebsc-1-s3.binance.org:8545/',
      chainId: 97,
      accounts: [process.env.PRIVATE_KEY],
    },
    bsc_mainnet: {
      url: 'https://bsc-dataseed.binance.org',
      chainId: 56,
      accounts: [process.env.PRIVATE_KEY],
    },
    avaxTest: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      accounts: [`${process.env.PRIVATE_KEY}`]
    },
    avaxMain: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      chainId: 43114,
      accounts: [`${process.env.PRIVATE_KEY}`]
    },
    ganache: {
      chainId: 1337,
      url: 'http://localhost:8545',
    },
  },
  etherscan: {
     apiKey: "N2E5BV7EU18ZEFEMGM8YS5NBPPQH9QJK3Q"
  },
}

setupDefaultNetworkProviders(config)

export default config
