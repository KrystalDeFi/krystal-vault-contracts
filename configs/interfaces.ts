export interface IConfig {
  autoVerifyContract?: boolean;
  sleepTime?: number;
  krystalVaultV3: {
    enabled?: boolean;
    autoVerifyContract?: boolean;
  };
  krystalVaultV3Factory?: {
    enabled?: boolean;
    autoVerifyContract?: boolean;
  };
  // For proxy admin
  proxyAdminMultisig?: string;
  // For managing the config and admin jobs
  adminMultisig?: string;
  // For maintaining, minting and some executing jobs
  maintainerMultisig?: string;
  uniswapV3Factory?: string;
}

export interface ITestConfig {
  nfpm: string;
}
