import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { parseEther } from "ethers";
import { ethers } from "hardhat";

import {
  StructHashEncoder,
  KrystalVault,
  KrystalVaultAutomator,
  KrystalVaultFactory,
  TestERC20,
} from "../typechain-types";

import { last } from "lodash";
import { NetworkConfig } from "../configs/networkConfig";
import { TestConfig } from "../configs/testConfig";
import { getMaxTick, getMinTick } from "../helpers/univ3";
import { blockNumber } from "../helpers/vm";
import { mockOrder } from "./MockOrder";

describe("KrystalVaultAutomator", () => {
  let alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let implementation: KrystalVault;
  let factory: KrystalVaultFactory;
  let vault: KrystalVault;
  let token0: TestERC20;
  let token1: TestERC20;
  let nfpmAddr = TestConfig.base_mainnet.nfpm;
  let automator: KrystalVaultAutomator;
  let operator: HardhatEthersSigner;

  beforeEach(async () => {
    [alice, bob, operator] = await ethers.getSigners();

    implementation = await ethers.deployContract("KrystalVault");

    await implementation.waitForDeployment();
    console.log("implementation deployed at: ", await implementation.getAddress());

    const optimalSwapper = await ethers.deployContract("PoolOptimalSwapper");
    await optimalSwapper.waitForDeployment();
    console.log("optimalSwapper deployed at: ", await optimalSwapper.getAddress());

    automator = await ethers.deployContract("KrystalVaultAutomator");
    await automator.waitForDeployment();
    await automator.initialize(operator);
    console.log("automator deployed at: ", await automator.getAddress());

    factory = await ethers.deployContract("KrystalVaultFactory", [
      NetworkConfig.base_mainnet.uniswapV3Factory,
      implementation,
      automator,
      optimalSwapper,
      NetworkConfig.base_mainnet.platformFeeRecipient,
      NetworkConfig.base_mainnet.platformFeeBasisPoint,
    ]);

    await factory.waitForDeployment();
    console.log("factory deployed at: ", await factory.getAddress());

    token0 = await ethers.deployContract("TestERC20", [parseEther("1000000")]);
    await token0.waitForDeployment();
    token1 = await ethers.deployContract("TestERC20", [parseEther("1000000")]);
    await token1.waitForDeployment();
    const t0Addr = await token0.getAddress();
    const t1Addr = await token1.getAddress();
    if (t1Addr < t0Addr) {
      [token0, token1] = [token1, token0];
    }

    console.log("token0: ", await token0.getAddress());
    console.log("token1: ", await token1.getAddress());

    await token0.transfer(alice, parseEther("1000"));
    await token1.transfer(alice, parseEther("1000"));

    const nfpm = await ethers.getContractAt("INonfungiblePositionManager", nfpmAddr, await ethers.provider.getSigner());
    await nfpm.createAndInitializePoolIfNecessary(
      await token0.getAddress(),
      await token1.getAddress(),
      3000,
      "79228162514264337593543950336", // initial price = 1
    );

    await token0.connect(alice).approve(factory, parseEther("1000"));
    await token1.connect(alice).approve(factory, parseEther("1000"));
    const tx = await factory.connect(alice).createVault(
      nfpm,
      {
        token0: await token0.getAddress(),
        token1: await token1.getAddress(),
        fee: 3000,
        tickLower: getMinTick(60),
        tickUpper: getMaxTick(60),
        amount0Desired: parseEther("1"),
        amount1Desired: parseEther("1"),
        amount0Min: parseEther("0.9"),
        amount1Min: parseEther("0.9"),
        recipient: alice,
        deadline: (await blockNumber()) + 100,
      },
      NetworkConfig.base_mainnet.ownerFeeBasisPoint || 50,
      "Vault Name",
      "VAULT",
    );

    const receipt = await tx.wait();
    // @ts-ignore
    const vaultAddress = last(receipt?.logs)?.args?.[1];
    vault = await ethers.getContractAt("KrystalVault", vaultAddress);
  });

  it("should execute automated order", async () => {
    const network = await ethers.provider.getNetwork();
    const sEncoder = await ethers.deployContract("StructHashEncoder");
    mockOrder.message.nfpmAddress = nfpmAddr;
    mockOrder.message.chainId = network.chainId.toString();
    const abiEncodedOrder = await sEncoder.encode(mockOrder.message);
    const domain = {
      name: "V3AutomationOrder",
      version: "4.0",
      chainId: network.chainId,
      verifyingContract: await automator.getAddress(),
    };
    const signature = await alice.signTypedData(domain, mockOrder.types, mockOrder.message);
    await automator.connect(operator).executeRebalance({
      vault: vault,
      newTickLower: -300,
      newTickUpper: 600,
      decreaseAmount0Min: 0,
      decreaseAmount1Min: 0,
      amount0Min: 0,
      amount1Min: 0,
      abiEncodedUserOrder: abiEncodedOrder,
      orderSignature: signature,
    });
    {
      const state = await vault.state();
      console.log("state: ", state);
      const pos = await vault.getBasePosition();
      console.log("pos token0: ", pos[1]);
      console.log("pos token1: ", pos[2]);
    }
    await automator.connect(operator).executeCompound(vault, 0, 0, abiEncodedOrder, signature);
    {
      const state = await vault.state();
      console.log("state: ", state);
      const pos = await vault.getBasePosition();
      console.log("pos token0: ", pos[1]);
      console.log("pos token1: ", pos[2]);
    }
    await automator.connect(operator).executeExit(vault, 0, 0, abiEncodedOrder, signature);
  });
  it("shouldn't execute if not operator", async () => {
  })
});
