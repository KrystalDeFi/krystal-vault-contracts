import { IConfig } from "./configUtils";

export const BaseConfig: Record<string, IConfig> = {
  base_mainnet: {
    sleepTime: 6 * 1000,
    krystalVaultV3Factory: {
      enabled: false,
      autoVerifyContract: true,
    },
    depositorVaultV3: {
      enabled: false,
      autoVerifyContract: true,
    },
    proxyAdminMultisig: "0xC1149cDA92B99CD17Ce66D82E599707f91D24BcA",
    adminMultisig: "0x3B9AB8e128D11318ef1a6Db27A2dF180f2f16A3A",
    maintainerMultisig: "0xC1149cDA92B99CD17Ce66D82E599707f91D24BcA",
    uniswapV3Factory: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD",
  },
};
