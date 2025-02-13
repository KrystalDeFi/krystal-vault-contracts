import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Contract, keccak256, parseEther } from "ethers";
import * as chai from "chai";

import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import krystalVaultV3ABI from "../abi/KrystalVaultV3.json";
import nfpmAbi from "../abi/INonfungiblePositionManager.json";
import { KrystalVaultV3Factory, TestERC20 } from "../typechain-types";
import { blockNumber } from "../helpers/vm";
import { BaseConfig } from "../scripts/config_base";
import { getMaxTick, getMinTick, tickToPrice } from "../helpers/univ3";

async function impersonateAccount(address: string): Promise<HardhatEthersSigner> {
  const signer = await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });
  return signer as HardhatEthersSigner;
}

describe("KrystalVaultV3Factory", function () {
  let owner: HardhatEthersSigner, alice: HardhatEthersSigner, bob: HardhatEthersSigner;
  let factory: KrystalVaultV3Factory;
  let vaultAddress: string;
  let token0: TestERC20;
  let token1: TestERC20;
  let nfpmAddr = "0x03a520b32C04BF3bEEf7BEb72E919cf822Ed34f1";

  beforeEach(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    factory = await ethers.deployContract("KrystalVaultV3Factory", [BaseConfig.base_mainnet.uniswapV3Factory]);
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
    await token0.transfer(await alice.getAddress(), parseEther("1000"));
    await token1.transfer(await alice.getAddress(), parseEther("1000"));
    console.log("token0", await token0.getAddress());
    console.log("token1", await token1.getAddress());

    const nfpm = new ethers.Contract(nfpmAddr, nfpmAbi, await ethers.provider.getSigner());
    const poolAddr = await nfpm.createAndInitializePoolIfNecessary(
      await token0.getAddress(),
      await token1.getAddress(),
      3000,
      "79228162514264337593543950336",
    );
    console.log("pool", poolAddr);
  });

  it("Should create a new vault", async () => {
    const tx = await factory.connect(alice).createVault(
      nfpmAddr,
      {
        token0: await token0.getAddress(),
        token1: await token1.getAddress(),
        fee: 3000,
        tickLower: getMinTick(-60),
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
