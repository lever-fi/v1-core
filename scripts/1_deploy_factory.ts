import { ethers } from "hardhat";

async function main() {
  const LeverV1Factory = await ethers.getContractFactory("LeverV1Factory");
  const leverV1Factory = await LeverV1Factory.deploy();
  await leverV1Factory.deployed();

  console.log(leverV1Factory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
