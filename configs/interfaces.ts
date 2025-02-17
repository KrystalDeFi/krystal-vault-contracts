export interface IConfig {
  autoVerifyContract?: boolean;
  sleepTime?: number;
  poolOptimalSwapper: {
    enabled?: boolean;
    autoVerifyContract?: boolean;
  };
  krystalVaultV3: {
    enabled?: boolean;
    autoVerifyContract?: boolean;
  };
  krystalVaultV3Factory?: {
    enabled?: boolean;
    autoVerifyContract?: boolean;
  };
  uniswapV3Factory?: string;
  // For platform fee recipient
  platformFeeRecipient?: string;
  // For platform fee in basis point
  platformFeeBasisPoint?: number;
  // For owner fee in basis point
  ownerFeeBasisPoint?: number;
}

export interface ITestConfig {
  nfpm: string;
}
