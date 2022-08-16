import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const NftCollection = await ethers.getContractFactory("ERC721Minimal");
  const nftCollection = await NftCollection.deploy("Lever NFT", "LFI");
  await nftCollection.deployed();

  // deploy marketplace
  /* const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(nftCollection.address);
  await marketplace.deployed(); */

  // mint nfts
  const mintTxn = await nftCollection.mint(
    "0x09b1769771a78D147CaFc5cCC971a94bDA5C342a",
    50
  );
  await mintTxn.wait();

  /* const LeverV1Pool = await ethers.getContractFactory("LeverV1Pool");
  const leverV1Pool = await LeverV1Pool.deploy(
    "0x0000000000000000000000000000000000000000", // factory
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
  await leverV1Pool.deployed(); */

  console.log(nftCollection.address);
  //console.log(marketplace.address);
  //console.log(leverV1Pool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
