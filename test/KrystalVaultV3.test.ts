import { ethers } from "hardhat";
import { Contract, parseEther } from "ethers";
import * as chai from "chai";
import { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import krystalVaultV3ABI from "../abi/KrystalVaultV3.json";
import { KrystalVaultV3Factory, TestERC20 } from "../typechain-types";

import { getMaxTick, getMinTick } from "../helpers/univ3";
import { blockNumber } from "../helpers/vm";
import { TestConfig } from "../configs/testConfig";
import { NetworkConfig } from "../configs/networkConfig";
import { last } from "lodash";

chai.use(chaiAsPromised);

describe("KrystalVaultV3Factory", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let factory: KrystalVaultV3Factory;
  let vaultAddress: string;
  let token0: TestERC20;
  let token1: TestERC20;
  let nfpmAddr = TestConfig.base_mainnet.nfpm;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    factory = await ethers.deployContract("KrystalVaultV3Factory", [NetworkConfig.base_mainnet.uniswapV3Factory]);

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

    await token0.transfer(await alice.getAddress(), parseEther("1000"));
    await token1.transfer(await alice.getAddress(), parseEther("1000"));

    await token0.connect(alice).approve(nfpmAddr, parseEther("1000"));
    await token1.connect(alice).approve(nfpmAddr, parseEther("1000"));

    const nfpm = await ethers.getContractAt("INonfungiblePositionManager", nfpmAddr, await ethers.provider.getSigner());
    await nfpm.createAndInitializePoolIfNecessary(
      await token0.getAddress(),
      await token1.getAddress(),
      3000,
      "79228162514264337593543950336", // initial price = 1
    );
  });

  it("Should create a new vault and return correct vault count", async () => {
    let vaultCount = await factory.allVaultsLength();
    expect(vaultCount).to.equal(0);

    await token0.connect(alice).approve(await factory.getAddress(), parseEther("1000"));
    await token1.connect(alice).approve(await factory.getAddress(), parseEther("1000"));

    const tx = await factory.connect(alice).createVault(
      nfpmAddr,
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
      "Vault Name",
      "VAULT",
    );

    const receipt = await tx.wait();
    // @ts-ignore
    vaultAddress = last(receipt?.logs)?.args?.[1];
    expect(vaultAddress).to.be.properAddress;

    vaultCount = await factory.allVaultsLength();
    expect(vaultCount).to.equal(1);
  });

  it("Should error when input wrong data", async () => {
    await token0.connect(alice).approve(await factory.getAddress(), parseEther("1000"));
    await token1.connect(alice).approve(await factory.getAddress(), parseEther("1000"));

    await expect(
      factory.connect(alice).createVault(
        nfpmAddr,
        {
          token0: await token0.getAddress(),
          token1: await token0.getAddress(),
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
        "Vault Name",
        "VAULT",
      ),
    ).to.be.revertedWithCustomError(factory, "IdenticalAddresses");

    await expect(
      factory.connect(alice).createVault(
        nfpmAddr,
        {
          token0: "0x0000000000000000000000000000000000000000",
          token1: await token0.getAddress(),
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
        "Vault Name",
        "VAULT",
      ),
    ).to.be.revertedWithCustomError(factory, "ZeroAddress");

    await expect(
      factory.connect(alice).createVault(
        nfpmAddr,
        {
          token0: await token0.getAddress(),
          token1: await token1.getAddress(),
          fee: 4000,
          tickLower: getMinTick(60),
          tickUpper: getMaxTick(60),
          amount0Desired: parseEther("1"),
          amount1Desired: parseEther("1"),
          amount0Min: parseEther("0.9"),
          amount1Min: parseEther("0.9"),
          recipient: alice,
          deadline: (await blockNumber()) + 100,
        },
        "Vault Name",
        "VAULT",
      ),
    ).to.be.revertedWithCustomError(factory, "InvalidFee");

    await expect(
      factory.connect(alice).createVault(
        nfpmAddr,
        {
          token0: "0x0000000000000000000000000000000000000001",
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
        "Vault Name",
        "VAULT",
      ),
    ).to.be.revertedWithCustomError(factory, "PoolNotFound");

    await expect(
      factory.connect(alice).createVault(
        nfpmAddr,
        {
          token0: await token0.getAddress(),
          token1: await token1.getAddress(),
          fee: 3000,
          tickLower: getMinTick(60),
          tickUpper: getMaxTick(60),
          amount0Desired: parseEther("1000000"),
          amount1Desired: parseEther("1000000"),
          amount0Min: parseEther("0.9"),
          amount1Min: parseEther("0.9"),
          recipient: alice,
          deadline: (await blockNumber()) + 100,
        },
        "Vault Name",
        "VAULT",
      ),
    ).to.be.revertedWithCustomError(token0, "ERC20InsufficientAllowance");
  });
});

describe("KrystalVaultV3", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;

  let vault: any;

  let aliceVaultContract: Contract;
  let bobVaultContract: Contract;

  let vaultAddress: string;

  beforeEach(async () => {
    await ethers.provider.send("hardhat_reset", []);
    [owner, alice, bob] = await ethers.getSigners();

    vault = await ethers.deployContract("KrystalVaultV3");
    await vault.waitForDeployment();

    vaultAddress = await vault.getAddress();

    aliceVaultContract = new ethers.Contract(vaultAddress, krystalVaultV3ABI, alice);

    bobVaultContract = new ethers.Contract(vaultAddress, krystalVaultV3ABI, bob);
  });

  ////// Happy Path
  it("Should deposit into the Vault", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);

    const aliceBalance = await aliceVaultContract.balanceOf(alice.address);
    expect(aliceBalance).to.be.gt(0);

    const totalSupply = await aliceVaultContract.totalSupply();
    expect(totalSupply).to.be.gt(0);
  });

  it("Should withdraw from the Vault", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);

    const shares = await aliceVaultContract.balanceOf(alice.address);
    await aliceVaultContract.withdraw(shares, alice.address, 0, 0);

    const aliceBalance = await aliceVaultContract.balanceOf(alice.address);
    expect(aliceBalance).to.equal(0);

    const totalSupply = await aliceVaultContract.totalSupply();
    expect(totalSupply).to.equal(0);
  });

  it("Should rebalance the Vault", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);

    await vault.rebalance(-600, 600, 0, 0, 0, 0);

    const [tickLower, tickUpper] = await vault.getCurrentTicks();
    expect(tickLower).to.equal(-600);
    expect(tickUpper).to.equal(600);
  });

  it("Should compound fees", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);

    await vault.compound(0, 0);

    const totalSupply = await aliceVaultContract.totalSupply();
    expect(totalSupply).to.be.gt(0);
  });
});
