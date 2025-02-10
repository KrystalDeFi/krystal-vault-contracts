import { ethers, network, run } from "hardhat";
import { NetworkConfig } from "./networkConfig";
import { KrystalVaultV3Factory } from "../typechain-types";
import { BaseContract } from "ethers";
import { IConfig } from "./configUtils";
import { sleep } from "./helpers";

const networkConfig = NetworkConfig[network.name];
if (!networkConfig) {
  throw new Error(`Missing deploy config for ${network.name}`);
}

export interface Contracts {
  krystalVaultV3Factory?: KrystalVaultV3Factory;
}

export const deploy = async (existingContract: Record<string, any> | undefined = undefined): Promise<Contracts> => {
  const [deployer] = await ethers.getSigners();

  const deployerAddress = await deployer.getAddress();

  log(0, "Start deployin contracts");
  log(0, "======================\n");

  let deployedContracts = await deployContracts(existingContract, deployerAddress);

  // Summary
  log(0, "Summary");
  log(0, "=======\n");

  log(0, JSON.stringify(convertToAddressObject(deployedContracts), null, 2));

  console.log("\nDeployment complete!");
  return deployedContracts;
};

async function deployContracts(
  existingContract: Record<string, any> | undefined = undefined,
  deployer: string,
): Promise<Contracts> {
  let step = 0;

  return {
    ...(await deployKrystalVaultV3FactoryContract(++step, existingContract, deployer)),
  };
}
export const deployKrystalVaultV3FactoryContract = async (
  step: number,
  existingContract: Record<string, any> | undefined,
  deployer: string,
  customNetworkConfig?: IConfig,
): Promise<Contracts> => {
  const config = { ...networkConfig, ...customNetworkConfig };

  let krystalVaultV3Factory;
  if (config.krystalVaultV3Factory?.enabled) {
    krystalVaultV3Factory = (await deployContract(
      `${step} >>`,
      config.krystalVaultV3Factory?.autoVerifyContract,
      "KrystalVaultV3Factory",
      existingContract?.["krystalVaultV3Factory"],
      "contracts/KrystalVaultV3Factory.sol:KrystalVaultV3Factory",
      config.uniswapV3Factory,
    )) as KrystalVaultV3Factory;
  }
  return {
    krystalVaultV3Factory,
  };
};

async function deployContract(
  step: number | string,
  autoVerify: boolean | undefined,
  contractName: string,
  contractAddress: string | undefined,
  contractLocation: string | undefined,
  ...args: any[]
): Promise<BaseContract> {
  log(1, `${step}. Deploying '${contractName}'`);
  log(1, "------------------------------------");
  const factory = await ethers.getContractFactory(contractName);
  let contract;

  if (contractAddress) {
    log(2, `> contract already exists`);
    log(2, `> address:\t${contractAddress}`);
    // TODO: Transfer admin if needed
    contract = factory.attach(contractAddress);
  } else {
    contract = await factory.deploy(...args);
    const tx = await contract.waitForDeployment();
    const deploymentTx = tx.deploymentTransaction();
    await printInfo(deploymentTx);
    log(2, `> address:\t${contract.target}`);
  }

  // Only verify new contract to save time or Try to verify no matter what
  if (autoVerify && !contractAddress) {
    // if (autoVerify) {
    try {
      log(3, ">> sleep first, wait for contract data to be propagated");
      await sleep(networkConfig.sleepTime ?? 60000);
      log(3, ">> start verifying");
      if (!!contractLocation) {
        await run("verify:verify", {
          address: contract.target,
          constructorArguments: args,
          contract: contractLocation,
        });
      } else {
        await run("verify:verify", {
          address: contract.target,
          constructorArguments: args,
        });
      }
      log(3, ">> done verifying");
    } catch (e) {
      log(2, "failed to verify contract", e);
    }
  }

  return contract;
}

async function printInfo(tx: any) {
  if (!tx) {
    log(5, `> tx is undefined`);
    return;
  }
  const receipt = await tx.wait(1);

  log(5, `> tx hash:\t${tx.hash}`);
  log(5, `> gas price:\t${tx.gasPrice?.toString()}`);
  log(5, `> gas used:\t${!!receipt && receipt.gasUsed.toString()}`);
}

export function convertToAddressObject(obj: Record<string, any> | Array<any> | BaseContract): any {
  if (obj === undefined) return obj;
  if (obj instanceof BaseContract) {
    return obj.target;
  } else if (Array.isArray(obj)) {
    return obj.map((k) => convertToAddressObject(obj[k]));
  } else if (typeof obj == "string") {
    return obj;
  } else {
    let ret = {};
    for (let k in obj) {
      // @ts-ignore
      ret[k] = convertToAddressObject(obj[k]);
    }
    return ret;
  }
}

let prevLevel: number;
function log(level: number, ...args: any[]) {
  if (prevLevel != undefined && prevLevel > level) {
    console.log("\n");
  }
  prevLevel = level;

  let prefix = "";
  for (let i = 0; i < level; i++) {
    prefix += "    ";
  }
  console.log(`${prefix}`, ...args);
}
