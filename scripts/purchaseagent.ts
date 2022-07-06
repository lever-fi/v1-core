import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const PurchaseAgent = await ethers.getContractFactory("PurchaseAgent");
  const purchaseAgent = await PurchaseAgent.deploy();
  await purchaseAgent.deployed();

  // deploy pool
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
  await leverV1Pool.deployed();
  console.log(purchaseAgent.address);
  console.log(leverV1Pool.address); */
  console.log(purchaseAgent.address);
}

/* bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter */

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
