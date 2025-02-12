import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, keccak256, parseEther } from "ethers";
import * as chai from "chai";

import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import krystalVaultV3ABI from "../abi/KrystalVaultV3.json";
import { KrystalVaultV3Factory } from "../typechain-types";
import { blockNumber } from "../helpers/vm";
import { BaseConfig } from "../scripts/config_base";
import { getMaxTick, getMinTick } from "../helpers/univ3";

describe("KrystalVaultV3Factory", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let factory: KrystalVaultV3Factory;
  let vaultAddress: string;

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    factory = await ethers.deployContract("KrystalVaultV3Factory", [BaseConfig.base_mainnet.uniswapV3Factory]);
    await factory.waitForDeployment();
  });

  it("Should create a new vault", async () => {
    const tx = await factory.createVault(
      "0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1",
      {
        token0: "0x4200000000000000000000000000000000000006",
        token1: "0x52C2b317eb0bb61e650683D2f287f56C413E4CF6",
        fee: 3000,
        tickLower: getMinTick(60),
        tickUpper: getMaxTick(60),
        amount0Desired: parseEther("0.1"),
        amount1Desired: parseEther("1000"),
        amount0Min: parseEther("0.09"),
        amount1Min: parseEther("900"),
        recipient: "0xC1149cDA92B99CD17Ce66D82E599707f91D24BcA",
        deadline: (await blockNumber()) + 100,
      },
      "Vault Name",
      "VAULT",
    );
    const receipt = await tx.wait();
    vaultAddress = receipt?.logs?.[0].data || "";
    expect(vaultAddress).to.be.properAddress;
  });

  it("Should return the correct number of vaults", async () => {
    await factory.createVault(
      "",
      {
        token0: "",
        token1: "",
        fee: "",
        tickLower: "",
        tickUpper: "",
        amount0Desired: "",
        amount1Desired: "",
        amount0Min: "",
        amount1Min: "",
        recipient: "",
        deadline: "",
      },
      "Vault Name",
      "VAULT",
    );
    const vaultCount = await factory.allVaultsLength();
    expect(vaultCount).to.equal(1);
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
