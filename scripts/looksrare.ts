import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const purchaseAgent = await ethers.getContractAt(
    "PurchaseAgent",
    "0xc6d95cA5cc00902D1EbB152d4E5dfe857FbeF0D5"
  );

  const data = ethers.utils.AbiCoder.prototype.encode(
    [
      "tuple(bool, address, address, uint256, uint256, uint256, address, address, uint256, uint256, uint256, uint256, bytes, uint8, bytes32, bytes32)",
    ],
    [
      [
        true,
        "0x33e5bC18d11945849dA9417ec85e4c3D430825cb",
        "0x104Edd8aABf30bDCc96252edb80aef9Fcb69fdD5",
        ethers.BigNumber.from("10000000000000000"),
        "1",
        1,
        "0x732319A3590E4fA838C111826f9584a9A2fDEa1a",
        "0xc778417E063141139Fce010982780140Aa0cD5Ab",
        "0",
        1655911599,
        1671463562,
        8500,
        [],
        28,
        "0x7c062419ea40d008075d0fa906ad634198398aee85e70f1f17e5e94188045afe",
        "0x39c8929325c49395ae7e2339246e323d23e6a57c8b9134e014dffad1099f73a7",
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
