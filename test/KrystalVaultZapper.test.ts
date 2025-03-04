import { expect } from "chai";
import { ethers, network } from "hardhat";
import { parseEther } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { TestERC20, KrystalVaultZapper } from "../typechain-types";
import { TestConfig } from "../configs/testConfig";

import { NetworkConfig } from "../configs/networkConfig";
import { swap100DaiToEthAndClankerData0, swap100DaiToEthAndClankerData1 } from "./MockSwapData";
import { last } from "lodash";

function getSlot(userAddress: string, mappingSlot: number) {
  return ethers.solidityPackedKeccak256(["uint256", "uint256"], [userAddress, mappingSlot]);
}

async function checkSlot(erc20: TestERC20, mappingSlot: any): Promise<boolean> {
  const contractAddress = await erc20.getAddress();
  const userAddress = ethers.ZeroAddress;

  // the slot must be a hex string stripped of leading zeros! no padding!
  // https://ethereum.stackexchange.com/questions/129645/not-able-to-set-storage-slot-on-hardhat-network
  const balanceSlot = getSlot(userAddress, mappingSlot);

  // storage value must be a 32 bytes long padded with leading zeros hex string
  const value = "0xdeadbeef";
  const storageValue = ethers.hexlify(ethers.zeroPadValue(value, 32));

  await ethers.provider.send("hardhat_setStorageAt", [contractAddress, balanceSlot, storageValue]);
  return (await erc20.balanceOf(userAddress)) == BigInt(value);
}

async function findBalanceSlot(erc20: TestERC20) {
  const snapshot = await network.provider.send("evm_snapshot");
  for (let slotNumber = 0; slotNumber < 100; slotNumber++) {
    try {
      if (await checkSlot(erc20, slotNumber)) {
        await ethers.provider.send("evm_revert", [snapshot]);
        return slotNumber;
      }
    } catch {}
    await ethers.provider.send("evm_revert", [snapshot]);
  }
  throw new Error("Could not find balance slot");
}

async function setErc20Balance(erc20: TestERC20, owner: HardhatEthersSigner, balance: BigInt) {
  const slot = await findBalanceSlot(erc20);
  const balanceSlot = getSlot(await owner.getAddress(), slot);
  const storageValue = ethers.hexlify(ethers.zeroPadValue("0x" + balance.toString(16), 32));
  await ethers.provider.send("hardhat_setStorageAt", [await erc20.getAddress(), balanceSlot, storageValue]);
}

describe("KrystalVaultZapper", () => {
  let dai: TestERC20;
  let clanker: TestERC20;
  let weth: TestERC20;
  let router = "0x6fD481970744F9Bc0044a81859FD92431a2Dd67D";
  // TestConfig.base_mainnet.krystalSwapRouter;
  let vaultZapper: KrystalVaultZapper;
  let alice: HardhatEthersSigner;

  before(async () => {
    dai = await ethers.getContractAt("TestERC20", "0x50c5725949a6f0c72e6c4a641f24049a917db0cb");
    clanker = await ethers.getContractAt("TestERC20", "0x1bc0c42215582d5a085795f4badbac3ff36d1bcb");
    weth = await ethers.getContractAt("TestERC20", "0x4200000000000000000000000000000000000006");
    let deployer, feeTaker;
    [deployer, feeTaker, alice] = await ethers.getSigners();

    const implementation = await ethers.deployContract("KrystalVault");
    const optimalSwapper = await ethers.deployContract("PoolOptimalSwapper");
    const factory = await ethers.deployContract("KrystalVaultFactory", [
      NetworkConfig.base_mainnet.uniswapV3Factory,
      implementation,
      NetworkConfig.base_mainnet.automatorAddress,
      optimalSwapper,
      NetworkConfig.base_mainnet.platformFeeRecipient,
      NetworkConfig.base_mainnet.platformFeeBasisPoint,
    ]);
    vaultZapper = await ethers.deployContract("KrystalVaultZapper", [factory, router, deployer, deployer, feeTaker]);
    await setErc20Balance(dai, alice, parseEther("100000"));
    // await setErc20Balance(froc, alice, parseEther("1000"));
    // await setErc20Balance(weth, alice, parseEther("1000"));
  });

  it("should zap in correctly", async () => {
    await dai.connect(alice).approve(vaultZapper, parseEther("10000"));
    const tx = await vaultZapper.connect(alice).swapAndCreateVault(
      {
        amount0: "0",
        amount1: "0",
        amount2: "1000000000000000000000",
        amountAddMin0: "4366576650162590802",
        amountAddMin1: "266687824774548680",
        amountIn0: "300907434907440334815",
        amountIn1: "698092565092559665165",
        amountOut0Min: "4851751841546960476",
        amountOut1Min: "296319805795666222",
        deadline: "1740733792",
        fee: "10000",
        nfpm: "0x03a520b32c04bf3beef7beb72e919cf822ed34f1",
        protocol: 0,
        protocolFeeX64: "18446744073709550",
        recipient: alice,
        swapData0: swap100DaiToEthAndClankerData0,
        swapData1: swap100DaiToEthAndClankerData1,
        swapSourceToken: "0x50c5725949a6f0c72e6c4a641f24049a917db0cb",
        tickLower: "-40800",
        tickUpper: "-34600",
        token0: "0x1bc0c42215582d5a085795f4badbac3ff36d1bcb",
        token1: "0x4200000000000000000000000000000000000006",
      },
      100,
      "WETH-DAI",
      "WETH-DAI",
    );

    const receipt = await tx.wait();
    // @ts-ignore
    const vaultAddress = ethers.dataSlice(receipt?.logs[receipt?.logs.length - 2]?.topics?.[2], 12, 32);

    expect(vaultAddress).to.be.properAddress;
    console.log("vaultAddress", vaultAddress);

    const vault = await ethers.getContractAt("KrystalVault", vaultAddress);
    {
      const pos = await vault.getBasePosition();
      console.log("pos", pos[1], pos[2]);
      const shares = await vault.balanceOf(await alice.getAddress());
      console.log("aliceShares", shares);
      expect(pos[1]).to.be.equal("5105277619660049891");
      expect(pos[2]).to.be.equal("329599260922291028");
      expect(shares).to.be.equal("464750776779987875");
    }
    // rebalance to swap
    await vault.connect(alice).rebalance(-44800, -30600, 0, 0, 0, 0, 0);
    await vault.connect(alice).rebalance(-40800, -34600, 0, 0, 0, 0, 0);

    await vaultZapper.connect(alice).swapAndDeposit({
      amount0: "0",
      amount1: "0",
      amount2: "1000000000000000000000",
      amountAddMin0: "4366576650162590802",
      amountAddMin1: "266687824774548680",
      amountIn0: "300907434907440334815",
      amountIn1: "698092565092559665165",
      amountOut0Min: "4851751841546960476",
      amountOut1Min: "296319805795666222",
      deadline: "1740733792",
      protocol: 0,
      protocolFeeX64: "18446744073709550",
      recipient: alice,
      swapData0: swap100DaiToEthAndClankerData0,
      swapData1: swap100DaiToEthAndClankerData1,
      swapSourceToken: "0x50c5725949a6f0c72e6c4a641f24049a917db0cb",
      vault: vaultAddress,
    });

    {
      const pos = await vault.getBasePosition();
      console.log("pos", pos[1], pos[2]);
      const shares = await vault.balanceOf(await alice.getAddress());
      console.log("aliceShares", shares);
      expect(pos[1]).to.be.equal("10189277394373537327");
      expect(pos[2]).to.be.equal("657826086377663630");
      expect(shares).to.be.equal("929945406242321330");
    }
  });
});
