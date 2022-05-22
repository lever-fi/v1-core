import { ethers } from "hardhat";

async function main() {
  // deploy nft
  const marketplace = await ethers.getContractAt(
    "Marketplace",
    "0x5ce40b8eb97ae722448E4911C26BB502D6A84D26"
  );

  const listTxn = await marketplace.list(0, ethers.utils.parseEther("0.02"));
  await listTxn.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
