import "hardhat-deploy";
import 'hardhat-watcher';
import "hardhat-tracer";
import * as dotenv from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-storage-layout";
import "hardhat-storage-layout-changes";
import { HardhatUserConfig } from "hardhat/config";
import { HttpNetworkUserConfig } from "hardhat/types";
dotenv.config({ path: __dirname + "/.env" });

const DEFAULT_MNEMONIC: string = process.env.MNEMONIC || "";

const sharedNetworkConfig: HttpNetworkUserConfig = {
  timeout: 8000000,
  gasPrice: "auto",
};
if (process.env.PRIVATE_KEY && process.env.PRIVATE_KEY_2) {
  sharedNetworkConfig.accounts = [process.env.PRIVATE_KEY,process.env.PRIVATE_KEY_2];
} else {
  sharedNetworkConfig.accounts = {
    mnemonic: process.env.MNEMONIC || DEFAULT_MNEMONIC,
  };
}

const config: HardhatUserConfig = {
  paths: {
    tests: "./test",
    cache: "./cache",
    deploy: "./src/deploy",
    sources: "./contracts",
    deployments: "./deployments",
    artifacts: "./artifacts"
  },

  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },

  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: {
        accountsBalance: "100000000000000000000000000000000000000000",
      },
      // forking:{
      // url: `https://arbitrum-mainnet.infura.io/v3/${process.env.INFURA_KEY}`
      // }
    },
    arbitrum: {
      ...sharedNetworkConfig,
      url: `https://arbitrum-mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
    },
    arbitrum_goerli: {
      ...sharedNetworkConfig,
      url: `https://arbitrum-goerli.infura.io/v3/${process.env.INFURA_KEY}`,
    }
  },
  etherscan: {
    apiKey: process.env.ARBITRUM_API_KEY,
  },
  watcher: {
    /* run npx hardhat watch compilation */
    compilation: {
      tasks: ["compile"],
      verbose: true,
    },
  },
};

export default config;
