import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const purchaseAgent = await ethers.getContractAt(
    "PurchaseAgent",
    "0xc6d95cA5cc00902D1EbB152d4E5dfe857FbeF0D5"
  );

  const data = ethers.utils.AbiCoder.prototype.encode(
    [
      "tuple(address, uint256, uint256, address, address, address, uint256, uint256, uint8, uint256, uint256, bytes32, uint256, bytes32, bytes32, uint256, tuple(uint256, address)[], bytes)",
    ],
    [
      [
        "0x0000000000000000000000000000000000000000",
        ethers.BigNumber.from(0),
        ethers.BigNumber.from("2000000000000000"),
        "0x31cf9ee05c444f2bf9a4892f82de1763abc9ab5b",
        "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
        "0x359fB071477A9Ad82835768F5ce9A29A0e5c1575",
        ethers.BigNumber.from(1902),
        ethers.BigNumber.from(1),
        ethers.BigNumber.from(3),
        ethers.BigNumber.from("1656777908"),
        ethers.BigNumber.from("1656864308"),
        "0x3000000000000000000000000000000000000000000000000000000000000000",
        ethers.BigNumber.from("168086152540198208932652290492459411181"),
        "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
        "bytes32",
        ethers.BigNumber.from(1),
        [
          [
            ethers.BigNumber.from(1),
            "0xc6d95cA5cc00902D1EbB152d4E5dfe857FbeF0D5",
          ],
        ],
        "0xb539afcc720e952ab107f2caddcc2c347e4d6d4ecc8d633c050fe72fda56caf3bf907fefa8556ad264b635ec3b3ffb3947dfe1db3cecc58c59d6f652e1b8c9ce", // bytes
      ],
    ]
  );

  purchaseAgent.purchase(1, data, {
    value: ethers.BigNumber.from("10000000000000000"),
    //gasLimit: 100000,
  });
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
