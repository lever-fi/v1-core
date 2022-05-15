import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { LeverV1Pool, ERC721Minimal } from "../src/Types";

/* describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
 */

describe("LeverV1Pool", () => {
  let alice: Signer, bob: Signer;
  let leverV1Pool: Contract /* : LeverV1Pool */;
  let nftCollection: Contract /* : ERC721Minimal */;
  let poolToken: Contract;

  before(async () => {
    [alice, bob] = await ethers.getSigners();
  });

  describe("Deploy Pool", () => {
    it("Deploy Collection", async () => {
      const NftCollection = await ethers.getContractFactory("ERC721Minimal");
      nftCollection = await NftCollection.deploy("Lever NFT", "LFI");
      await nftCollection.deployed();

      expect(await nftCollection.name()).to.equal("Lever NFT");
      expect(await nftCollection.symbol()).to.equal("LFI");
    });

    it("Create Pool", async () => {
      const LeverV1Pool = await ethers.getContractFactory("LeverV1Pool");
      leverV1Pool = await LeverV1Pool.deploy(
        await alice.getAddress(),
        nftCollection.address,
        0,
        0,
        0
      );
      await leverV1Pool.deployed();

      poolToken = await ethers.getContractAt(
        "LeverV1ERC20Essential",
        await leverV1Pool.poolToken()
      );
    });
  });

  describe("Deposit", () => {
    describe("A", () => {
      const DEPOSIT = "90";

      before(async () => {
        const depositTxn = await leverV1Pool.connect(alice).deposit({
          value: ethers.utils.parseEther(DEPOSIT),
        });
        await depositTxn.wait();
      });

      it("Liquidity", async () => {
        expect(await waffle.provider.getBalance(leverV1Pool.address)).to.equal(
          ethers.utils.parseEther(DEPOSIT)
        );
      });

      it("Token", async () => {
        expect(await poolToken.balanceOf(await alice.getAddress())).to.equal(
          ethers.utils.parseEther(DEPOSIT)
        );
      });
    });

    describe("B", () => {
      const DEPOSIT = "5";

      before(async () => {
        const accrueTxn = await alice.sendTransaction({
          to: leverV1Pool.address,
          value: ethers.utils.parseEther("5"),
        });
        await accrueTxn.wait();

        const depositTxn = await leverV1Pool.connect(bob).deposit({
          value: ethers.utils.parseEther(DEPOSIT),
        });
        await depositTxn.wait();
      });

      it("Liquidity", async () => {
        expect(await waffle.provider.getBalance(leverV1Pool.address)).to.equal(
          ethers.utils.parseEther("100")
        );
      });

      it("Token", async () => {
        expect(await poolToken.balanceOf(await bob.getAddress())).to.equal(
          ethers.BigNumber.from("4736842105263157894")
        );
      });
    });
  });

  describe("Collect", () => {
    describe("A", () => {
      let alicePrevBalance: BigNumber;

      before(async () => {
        alicePrevBalance = await alice.getBalance();
        const collectTxn = await leverV1Pool
          .connect(alice)
          .collect(ethers.utils.parseEther("10"));
        await collectTxn.wait();
      });

      it("Liquidity", async () => {
        expect(await waffle.provider.getBalance(leverV1Pool.address)).to.equal(
          ethers.BigNumber.from("89444444444444444500")
        );
      });

      it("Token", async () => {
        expect(await poolToken.balanceOf(await alice.getAddress())).to.equal(
          ethers.utils.parseEther("80")
        );
      });

      it("Ether", async () => {
        expect(await alice.getBalance()).to.be.above(alicePrevBalance);
      });
    });
  });
});
