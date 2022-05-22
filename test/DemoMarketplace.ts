import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { Marketplace, ERC721Minimal } from "../src/Types";

describe("Marketplace", () => {
  let alice: Signer, bob: Signer;
  let marketplace: Contract;
  let nftCollection: Contract;

  before(async () => {
    [alice, bob] = await ethers.getSigners();
  });

  describe("Deploy", () => {
    it("Deploy Collection", async () => {
      const NftCollection = await ethers.getContractFactory("ERC721Minimal");
      nftCollection = await NftCollection.deploy("Lever NFT", "LFI");
      await nftCollection.deployed();

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
  });

  describe("Functionalize", () => {
    it("Deposit", async () => {
      const depositTxn = await alice.sendTransaction({
        to: marketplace.address,
        value: ethers.utils.parseEther("5"),
      });
      await depositTxn.wait();

      expect(await waffle.provider.getBalance(marketplace.address)).to.equal(
        ethers.utils.parseEther("5")
      );
    });

    it("List", async () => {
      const listTxn = await marketplace
        .connect(alice)
        .list(BigNumber.from(1), ethers.utils.parseEther("0.5"));
      await listTxn.wait();

      expect(await marketplace.listings(1)).to.equal(
        ethers.utils.parseEther("0.5")
      );
    });

    it("Purchase", async () => {
      const purchaseTxn = await marketplace
        .connect(alice)
        .purchase(BigNumber.from(1), {
          value: ethers.utils.parseEther("0.5"),
        });
      await purchaseTxn.wait();

      expect(await nftCollection.ownerOf(BigNumber.from(1))).to.equal(
        await alice.getAddress()
      );
      expect(await nftCollection.balanceOf(await alice.getAddress())).to.equal(
        BigNumber.from(1)
      );
    });

    it("Sell", async () => {
      const prevBal = await alice.getBalance();
      const sellTxn = await marketplace
        .connect(alice)
        .sell(BigNumber.from(1), BigNumber.from(1));
      await sellTxn.wait();

      expect(await alice.getBalance()).to.be.below(
        prevBal.add(BigNumber.from(1))
      );
      expect(await nftCollection.balanceOf(await alice.getAddress())).to.equal(
        BigNumber.from(0)
      );
    });
  });
});
