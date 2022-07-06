import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { BigNumber, Contract, Signer, Wallet } from "ethers";
import { PurchaseAgent } from "../src/Types";

describe("LeverV1Pool", () => {
  let alice: Signer, bob: Signer;
  let agent: Contract;

  before(async () => {
    [alice, bob] = await ethers.getSigners();
  });

  describe("Setup", () => {
    it("Deploy Agent", async () => {
      const Agent = await ethers.getContractFactory("PurchaseAgent");
      agent = await Agent.deploy();
      await agent.deployed();
    });

    it("Test Agent", async () => {
      const data = ethers.utils.defaultAbiCoder.encode(
        [
          "tuple(bool, address, address, uint256, uint256, uint256, address, address, uint256, uint256, uint256, uint256, bytes, uint8, bytes32, bytes32)",
        ],
        [
          [
            true,
            "0x33e5bC18d11945849dA9417ec85e4c3D430825cb",
            "0x104Edd8aABf30bDCc96252edb80aef9Fcb69fdD5",
            ethers.BigNumber.from("10000000000000000"),
            ethers.BigNumber.from("1"),
            ethers.BigNumber.from("1"),
            "0x732319A3590E4fA838C111826f9584a9A2fDEa1a",
            "0xc778417E063141139Fce010982780140Aa0cD5Ab",
            ethers.BigNumber.from("0"),
            ethers.BigNumber.from("1655911599"),
            ethers.BigNumber.from("1671463562"),
            ethers.BigNumber.from("8500"),
            [],
            ethers.BigNumber.from("28"),
            "0x7c062419ea40d008075d0fa906ad634198398aee85e70f1f17e5e94188045afe",
            "0x39c8929325c49395ae7e2339246e323d23e6a57c8b9134e014dffad1099f73a7",
          ],
        ]
      );

      await agent.purchase(1, data, {
        value: ethers.BigNumber.from("10000000000000000"),
        //gasLimit: 100000,
      });
    });
  });
});
