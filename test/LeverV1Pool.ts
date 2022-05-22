import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { BigNumber, Contract, Signer, Wallet } from "ethers";
import { LeverV1Pool, ERC721Minimal, Marketplace } from "../src/Types";

describe("LeverV1Pool", () => {
  let alice: Signer, bob: Signer;
  let leverV1Pool: Contract /* : LeverV1Pool */;
  let nftCollection: Contract /* : ERC721Minimal */;
  let marketplace: Contract;
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

    it("Setup Marketplace", async () => {
      const Marketplace = await ethers.getContractFactory("Marketplace");
      marketplace = await Marketplace.deploy(nftCollection.address);
      await marketplace.deployed();

      const approveTxn = await nftCollection
        .connect(alice)
        .setApprovalForAll(marketplace.address, true);
      await approveTxn.wait();
    });

    it("Mint collection", async () => {
      const mintTxn = await nftCollection
        .connect(alice)
        .mint(marketplace.address, 10);
      await mintTxn.wait();

      expect(await nftCollection.totalSupply()).to.equal(BigNumber.from("10"));
    });

    it("Create Pool", async () => {
      const LeverV1Pool = await ethers.getContractFactory("LeverV1Pool");
      leverV1Pool = await LeverV1Pool.deploy(
        await alice.getAddress(), // factory
        marketplace.address, // temp - marketplace
        "0x0000000000000000000000000000000000000000", // oracle
        nftCollection.address, // collection ✔️
        ethers.utils.parseEther("40").div(1e2), // collateral coverage ratio (40%)
        ethers.utils.parseEther("14").div(1e3), // interest rate (1.4%)
        ethers.BigNumber.from(60 * 60 * 24), // compound daily
        ethers.utils.parseEther("15").div(1e2), // burn rate (15%)
        0, // loan term
        ethers.utils.parseEther("30"), // min liquidity ✔️
        ethers.utils.parseEther("5").div(1e2) // min deposit (0.05 ETH) ✔️
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

  describe("Borrow", () => {
    const targetTokenId = BigNumber.from(1);
    let wrappedCollection: Contract;

    before(async () => {
      /* console.log(
        ethers.utils.formatEther(
          await waffle.provider.getBalance(leverV1Pool.address)
        )
      ); */
      wrappedCollection = await ethers.getContractAt(
        "ERC721Minimal",
        await leverV1Pool.wrappedCollection()
      );
    });

    it("Setup Marketplace", async () => {
      const depositTxn = await alice.sendTransaction({
        to: marketplace.address,
        value: ethers.utils.parseEther("5"),
      });
      await depositTxn.wait();

      expect(await waffle.provider.getBalance(marketplace.address)).to.equal(
        ethers.utils.parseEther("5")
      );

      const listTxn = await marketplace
        .connect(alice)
        .list(targetTokenId, ethers.utils.parseEther("0.5"));
      await listTxn.wait();

      expect(await marketplace.listings(targetTokenId)).to.equal(
        ethers.utils.parseEther("0.5")
      );
    });

    it("Borrow", async () => {
      const priorPoolBalance = await waffle.provider.getBalance(
        leverV1Pool.address
      );
      const borrowTxn = await leverV1Pool.connect(bob).borrow(targetTokenId, {
        value: ethers.utils.parseEther("0.3"),
      });
      await borrowTxn.wait();

      expect(
        await wrappedCollection.balanceOf(await bob.getAddress())
      ).to.equal(BigNumber.from(1));
      expect(await nftCollection.balanceOf(leverV1Pool.address)).to.equal(
        BigNumber.from(1)
      );
      expect(await waffle.provider.getBalance(leverV1Pool.address)).to.equal(
        priorPoolBalance.sub(await ethers.utils.parseEther("0.2"))
      );
    });

    it("Repay Part 1", async () => {
      // repay partial
      const repayTxn = await leverV1Pool.connect(bob).repay(targetTokenId, {
        value: ethers.utils.parseEther("0.1"),
      });
      await repayTxn.wait();
    });

    it("Repay Part 2", async () => {
      // finalized repayment installment
      const repayTxn = await leverV1Pool.connect(bob).repay(targetTokenId, {
        value: ethers.utils.parseEther("0.3"),
      });
      await repayTxn.wait();

      expect(
        await wrappedCollection.balanceOf(await bob.getAddress())
      ).to.equal(BigNumber.from(0));
      expect(await nftCollection.balanceOf(leverV1Pool.address)).to.equal(
        BigNumber.from(0)
      );
      expect(await nftCollection.balanceOf(await bob.getAddress())).to.equal(
        BigNumber.from(1)
      );

      /* console.log(
        ethers.utils.formatEther(
          await waffle.provider.getBalance(leverV1Pool.address)
        )
      ); */
    });
  });
});
