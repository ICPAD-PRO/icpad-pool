import '@nomiclabs/hardhat-waffle'

require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("./task/IDOPoolFactory")
require("./task/ICPadStake")

require('dotenv').config();

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';

const config = {
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            accounts: [{
                privateKey: process.env.MAINNET_PRIVATE_KEY,
                balance: "10000000"
            }
            ]
        },
        ropsten: {
            url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [process.env.ROPSTEN_PRIVATE_KEY]
        },
        mainnet: {
            url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
            accounts: [
                process.env.MAINNET_PRIVATE_KEY || ''
            ].filter((item) => item !== '')
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
            blockGasLimit: 12000000,
            gas: 21000000,
            gasPrice: 2000000000,
            accounts: [
                process.env.RINKEBY_PRIVATE_KEY || '',
                process.env.RINKEBY_PRIVATE_KEY_SECONDARY || ''
            ].filter((item) => item !== '')
        },
        testnet_bsc: {
            url: "https://data-seed-prebsc-1-s1.binance.org:8545",
            chainId: 97,
            gasPrice: 20000000000,
            accounts: [
                process.env.TEST_BSC_PRIVATE_KEY
            ]
        },
        mainnet_bsc: {
            url: "https://bsc-dataseed.binance.org/",
            chainId: 56,
            gasPrice: 20000000000,
            accounts: [
                process.env.MAINNET_BSC_PRIVATE_KEY
            ]
        },
        frame: {
            url: 'http://localhost:1248'
        }
    },
    solidity: {
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
        version: '0.6.12',
    },
    etherscan: {apiKey: ETHERSCAN_API_KEY}

}
module.exports = config;
