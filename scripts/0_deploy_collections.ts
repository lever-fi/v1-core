import { ethers } from "hardhat";
import { BigNumber } from "ethers";

interface Collection {
  name: String;
  symbol: String;
  amount: BigNumber;
  owner: String;
  baseURI: String;
}

const collections: Collection[] = [
  {
    name: "Lever Sample Bored Ape Yacht Club",
    symbol: "LSBAYC",
    amount: BigNumber.from(50),
    owner: "0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051",
    baseURI: "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
  },
  {
    name: "Lever Sample Doodles",
    symbol: "LSDOODLE",
    amount: BigNumber.from(50),
    owner: "0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051",
    baseURI: "ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/",
  },
  {
    name: "Lever Sample Moon Birds",
    symbol: "LSMOON",
    amount: BigNumber.from(50),
    owner: "0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051",
    baseURI: "https://live---metadata-5covpqijaa-uc.a.run.app/metadata/",
  },
  {
    name: "Lever Sample Azuki",
    symbol: "LSAZUKI",
    amount: BigNumber.from(50),
    owner: "0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051",
    baseURI:
      "https://ikzttp.mypinata.cloud/ipfs/QmQFkLSQysj94s5GvTHPyzTxrawwtjgiiYS2TBLgrvw8CW/",
  },
];

async function main() {
  const NftCollection = await ethers.getContractFactory("ERC721Minimal");

  for (const collection of collections) {
    const nftCollection = await NftCollection.deploy(
      collection.name,
      collection.symbol,
      collection.baseURI
    );
    await nftCollection.deployed();
    console.log(
      `${collection.name} (${collection.symbol}) - ${nftCollection.address}`
    );

    const mintTxn = await nftCollection.mint(
      collection.owner,
      collection.amount
    );
    await mintTxn.wait();
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
