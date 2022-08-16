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
          "tuple(address, uint256, uint256, address, address, address, uint256, uint256, uint8, uint256, uint256, bytes32, uint256, bytes32, bytes32, uint256, tuple(uint256, address)[], bytes)",
          "uint256",
        ],
        [
          [
            "0x0000000000000000000000000000000000000000", // consideration token
            ethers.BigNumber.from("0"), // consideration identifier
            ethers.BigNumber.from("2"), // consideration amount
            "0x6e84150012fd6d571c33c266424fcdecf80e3274", // offerer
            "0x00000000E88FE2628EbC5DA81d2b3CeaD633E89e", // zone
            "0x5CD3A8b0842c29f5FaaAF09a990B61e24FD68bb8", // collection address
            ethers.BigNumber.from(56), // token id
            ethers.BigNumber.from(1), // collection amount
            ethers.BigNumber.from(3), // order type
            ethers.BigNumber.from("1659009620"), // start time
            ethers.BigNumber.from("1661688020"), // end time
            "0x0000000000000000000000000000000000000000000000000000000000000000", // zone hash
            ethers.BigNumber.from("83829219237913258"), // salt
            "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000", // offerer conduit key
            "0x0000000000000000000000000000000000000000000000000000000000000000", // fulfiller conduit key
            ethers.BigNumber.from("2"), // original additional recipients
            [
              [
                ethers.BigNumber.from("195000000000000000"), // amount
                "0x6E84150012Fd6D571C33C266424fcDEcF80E3274", // recipient
              ],
              [
                ethers.BigNumber.from("5000000000000000"), // amount
                "0x8De9C5A032463C561423387a9648c5C7BCC5BC90", // recipient
              ],
            ],
            "0xd82ad34b643eeb16a49d9b5b2b92aea10423b579357d1ee03feedf88745352007760dd23bd050ff3d279cb199e7bf93095d65d369b2c8400be6cc95fc09e71671c", // signature
          ],
          ethers.utils.parseEther("0.2"),
        ]
      );

      const txn = await agent.callStatic.test(0, data, {
        value: ethers.utils.parseEther("0.2"),
        gasLimit: 100000,
      });

      console.log(txn);

      //wait txn.wait();
    });
  });
});
