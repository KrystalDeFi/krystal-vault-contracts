import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, keccak256, parseEther } from "ethers";
import * as chai from "chai";

import chaiAsPromised from "chai-as-promised";
chai.use(chaiAsPromised);
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import krystalVaultV3ABI from "../abi/KrystalVaultV3.json";

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
  it("Should deposit into the Vault", async () => {});
});
