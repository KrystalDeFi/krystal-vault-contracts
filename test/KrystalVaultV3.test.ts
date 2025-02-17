import { ethers } from "hardhat";
import { Contract, parseEther } from "ethers";
import * as chai from "chai";
import { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import krystalVaultV3ABI from "../abi/KrystalVaultV3.json";
import { KrystalVaultV3, KrystalVaultV3Factory, TestERC20 } from "../typechain-types";

import { getMaxTick, getMinTick } from "../helpers/univ3";
import { blockNumber } from "../helpers/vm";
import { TestConfig } from "../configs/testConfig";
import { NetworkConfig } from "../configs/networkConfig";
import { last } from "lodash";

chai.use(chaiAsPromised);

describe("KrystalVaultV3Factory", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let implementation: KrystalVaultV3;
  let factory: KrystalVaultV3Factory;
  let vaultAddress: string;
  let token0: TestERC20;
  let token1: TestERC20;
  let nfpmAddr = TestConfig.base_mainnet.nfpm;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    implementation = await ethers.deployContract("KrystalVaultV3");

    await implementation.waitForDeployment();

    const implementationAddress = await implementation.getAddress();
    console.log("implementation deployed at: ", implementationAddress);

    const optimalSwapper = await ethers.deployContract("PoolOptimalSwapper");
    await optimalSwapper.waitForDeployment();

    factory = await ethers.deployContract("KrystalVaultV3Factory", [
      NetworkConfig.base_mainnet.uniswapV3Factory,
      implementationAddress,
      optimalSwapper,
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

  ////// Happy Path
  it("Should create a new vault and return correct vault count", async () => {
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
    expect(await factory.allVaults(0)).to.equal(vaultAddress);
  });

  ////// Error Path
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

  ////// Error Path
  it("Should not create vault while contract is paused", async () => {
    await factory.connect(owner).pause();
    await token0.connect(alice).approve(await factory.getAddress(), parseEther("1000"));
    await token1.connect(alice).approve(await factory.getAddress(), parseEther("1000"));

    await expect(
      factory.connect(alice).createVault(
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
      ),
    ).to.be.revertedWithCustomError(factory, "EnforcedPause");
  });
});

describe("KrystalVaultV3", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let token0: TestERC20, token1: TestERC20;

  let aliceVaultContract: KrystalVaultV3;
  let bobVaultContract: KrystalVaultV3;

  let vaultAddress: string;
  let nfpmAddr = TestConfig.base_mainnet.nfpm;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    const implementation = await ethers.deployContract("KrystalVaultV3");

    await implementation.waitForDeployment();

    const implementationAddress = await implementation.getAddress();
    console.log("implementation deployed at: ", implementationAddress);

    const optimalSwapper = await ethers.deployContract("PoolOptimalSwapper");
    await optimalSwapper.waitForDeployment();

    const factory = await ethers.deployContract("KrystalVaultV3Factory", [
      NetworkConfig.base_mainnet.uniswapV3Factory,
      implementationAddress,
      optimalSwapper,
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
    await token0.transfer(bob, parseEther("1000"));
    await token1.transfer(bob, parseEther("1000"));

    const nfpm = await ethers.getContractAt("INonfungiblePositionManager", nfpmAddr, await ethers.provider.getSigner());
    await nfpm.createAndInitializePoolIfNecessary(
      await token0.getAddress(),
      await token1.getAddress(),
      3000,
      "79228162514264337593543950336", // initial price = 1
    );

    {
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
        "Alice Vault",
        "VAULT",
      );

      const receipt = await tx.wait();
      // @ts-ignore
      vaultAddress = last(receipt?.logs)?.args?.[1];
      console.log("aliceVaultContract deployed at: ", vaultAddress);
      aliceVaultContract = await ethers.getContractAt("KrystalVaultV3", vaultAddress, alice);
    }

    {
      await token0.connect(bob).approve(await factory.getAddress(), parseEther("1000"));
      await token1.connect(bob).approve(await factory.getAddress(), parseEther("1000"));
      const tx = await factory.connect(bob).createVault(
        nfpmAddr,
        {
          token0: await token0.getAddress(),
          token1: await token1.getAddress(),
          fee: 3000,
          tickLower: getMinTick(60),
          tickUpper: getMaxTick(60),
          amount0Desired: parseEther("100"),
          amount1Desired: parseEther("100"),
          amount0Min: parseEther("0.9"),
          amount1Min: parseEther("0.9"),
          recipient: bob,
          deadline: (await blockNumber()) + 100,
        },
        "Bob Vault",
        "VAULT",
      );

      const receipt = await tx.wait();
      // @ts-ignore
      vaultAddress = last(receipt?.logs)?.args?.[1];
      console.log("bobVault deployed at: ", vaultAddress);
      bobVaultContract = await ethers.getContractAt("KrystalVaultV3", vaultAddress, bob);
    }
  });

  ////// Happy Path
  it("Should deposit and withdraw from Vault", async () => {
    const amount0Desired = parseEther("2");
    const amount1Desired = parseEther("2");
    let balance0Before: bigint;
    let balance1Before: bigint;
    let balance0After: bigint;
    let balance1After: bigint;

    await token0.transfer(bob, parseEther("1000"));
    await token1.transfer(bob, parseEther("1000"));
    token0.connect(bob).approve(await aliceVaultContract.getAddress(), parseEther("1000"));
    token1.connect(bob).approve(await aliceVaultContract.getAddress(), parseEther("1000"));

    console.log("vault bal0", await token0.balanceOf(aliceVaultContract));
    console.log("vault bal1", await token1.balanceOf(aliceVaultContract));
    balance0Before = await token0.balanceOf(bob);
    balance1Before = await token1.balanceOf(bob);
    await aliceVaultContract.connect(bob).deposit(amount0Desired, amount1Desired, 0, 0, bob.address);
    console.log("vault bal0 after", await token0.balanceOf(aliceVaultContract));
    console.log("vault bal1 after", await token1.balanceOf(aliceVaultContract));
    balance0After = await token0.balanceOf(bob);
    balance1After = await token1.balanceOf(bob);

    expect(balance0After - balance0Before).to.equal(parseEther("-2"), "deposit balance0");
    expect(balance1After - balance1Before).to.equal(parseEther("-2"), "deposit balance1");

    let bobBalance = await aliceVaultContract.balanceOf(bob.address);
    expect(bobBalance).to.be.gt(0);
    console.log("bob balance: ", bobBalance.toString());

    balance0Before = await token0.balanceOf(bob);
    balance1Before = await token1.balanceOf(bob);
    await aliceVaultContract.connect(bob).withdraw(bobBalance / BigInt(2), bob, 0, 0);
    balance0After = await token0.balanceOf(bob);
    balance1After = await token1.balanceOf(bob);

    bobBalance = await aliceVaultContract.balanceOf(bob.address);
    console.log("bob balance: ", bobBalance.toString());

    expect(balance0After - balance0Before).to.equal(BigInt("999999999999999999"), "withdraw balance0");
    expect(balance1After - balance1Before).to.equal(BigInt("999999999999999999"), "withdraw balance1");

    const totalSupply = await aliceVaultContract.totalSupply();
    expect(totalSupply).to.be.gt(0);
  });

  ////// Happy Path
  it("Should rebalance the Vault", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await token0.connect(alice).approve(aliceVaultContract, parseEther("1000"));
    await token1.connect(alice).approve(aliceVaultContract, parseEther("1000"));

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);
    await aliceVaultContract.rebalance(-300, 600, 0, 0, 0, 0);

    const state = await aliceVaultContract.state();
    expect(state.currentTickLower).to.equal(-300);
    expect(state.currentTickUpper).to.equal(600);
    const pos = await aliceVaultContract.getBasePosition();
    console.log(pos);
    expect(pos[1]).to.be.equal(BigInt("2346332740274337647"));
    expect(pos[2]).to.be.equal(BigInt("1651417881126655081"));
    console.log(await token0.balanceOf(aliceVaultContract));
    console.log(await token1.balanceOf(aliceVaultContract));
  });

  ////// Happy Path
  it("Should compound fees", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await token0.connect(alice).approve(aliceVaultContract, parseEther("1000"));
    await token1.connect(alice).approve(aliceVaultContract, parseEther("1000"));

    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address);
    // Do a rebalance to swap
    await aliceVaultContract.rebalance(-300, 600, 0, 0, 0, 0);
    console.log("token0 balance: ", await token0.balanceOf(aliceVaultContract));
    console.log("token1 balance: ", await token1.balanceOf(aliceVaultContract));
    const posBefore = await aliceVaultContract.getBasePosition();
    await aliceVaultContract.compound(0, 0);
    const posAfter = await aliceVaultContract.getBasePosition();
    expect(posAfter[0] - posBefore[0]).to.be.gt(0);
    expect(posAfter[1] - posBefore[1]).to.be.gt(0);
    expect(posAfter[2] - posBefore[2]).to.be.gt(0);

    console.log("token0 balance: ", await token0.balanceOf(aliceVaultContract));
    console.log("token1 balance: ", await token1.balanceOf(aliceVaultContract));

    const totalSupply = await aliceVaultContract.totalSupply();
    expect(totalSupply).to.be.gt(0);
  });
  it("Should exit and allow other to withdraw", async () => {
    const amount0Desired = parseEther("1");
    const amount1Desired = parseEther("1");

    await token0.connect(alice).approve(aliceVaultContract, parseEther("1000"));
    await token1.connect(alice).approve(aliceVaultContract, parseEther("1000"));

    // deposit to bob
    await aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, bob.address);
    const bobBalance = await aliceVaultContract.balanceOf(bob.address);
    expect(bobBalance).to.be.gt(0);
    console.log("bob shares: ", bobBalance.toString());
    const aliceBalance0Before = await token0.balanceOf(alice.address);
    const aliceBalance1Before = await token1.balanceOf(alice.address);
    // alice exit position
    await aliceVaultContract.exit(alice.address, 0, 0);
    const aliceBalance0After = await token0.balanceOf(alice.address);
    const aliceBalance1After = await token1.balanceOf(alice.address);
    expect(aliceBalance0After - aliceBalance0Before).to.be.gt(0);
    expect(aliceBalance1After - aliceBalance1Before).to.be.gt(0);
    console.log("alice token0 withdrawn: ", aliceBalance0After - aliceBalance0Before);
    console.log("alice token1 withdrawn: ", aliceBalance1After - aliceBalance1Before);

    await expect(
      aliceVaultContract.deposit(amount0Desired, amount1Desired, 0, 0, alice.address),
    ).to.be.revertedWithCustomError(aliceVaultContract, "InvalidPosition");

    const bobBalance0Before = await token0.balanceOf(bob.address);
    const bobBalance1Before = await token1.balanceOf(bob.address);
    await aliceVaultContract.connect(bob).withdraw(bobBalance, bob, 0, 0);
    const bobBalance0After = await token0.balanceOf(bob.address);
    const bobBalance1After = await token1.balanceOf(bob.address);
    expect(bobBalance0After - bobBalance0Before).to.be.gt(0);
    expect(bobBalance1After - bobBalance1Before).to.be.gt(0);
    console.log("bob token0 withdrawn: ", bobBalance0After - bobBalance0Before);
    console.log("bob token1 withdrawn: ", bobBalance1After - bobBalance1Before);
  });

  ////// Error Path
  it("Should not available to mint position again", async () => {
    await expect(aliceVaultContract.mintPosition(alice.address, 0, 0, 0, 0)).to.be.revertedWithCustomError(
      aliceVaultContract,
      "Unauthorized",
    );
  });

  ////// Error Path
  it("Should not available to action if not authorized", async () => {
    await expect(aliceVaultContract.connect(bob).exit(bob.address, 0, 0)).to.be.revertedWithCustomError(
      aliceVaultContract,
      "AccessControlUnauthorizedAccount",
    );

    await expect(aliceVaultContract.connect(bob).rebalance(0, 0, 0, 0, 0, 0)).to.be.revertedWithCustomError(
      aliceVaultContract,
      "AccessControlUnauthorizedAccount",
    );

    await expect(aliceVaultContract.connect(bob).compound(0, 0)).to.be.revertedWithCustomError(
      aliceVaultContract,
      "AccessControlUnauthorizedAccount",
    );
  });
});
