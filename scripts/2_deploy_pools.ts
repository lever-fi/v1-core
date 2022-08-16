import { ethers } from "hardhat";
import { utils, BigNumber } from "ethers";

interface Pool {
  originalCollection: String;
  collateralCoverageRatio: BigNumber;
  interestRate: BigNumber;
  chargeInterval: BigNumber;
  burnRate: BigNumber;
  loanTerm: BigNumber;
  minLiquidity: BigNumber;
  minDeposit: BigNumber;
  paymentFrequency: BigNumber;
}

const pools: Pool[] = [
  {
    originalCollection: "0x0dB7b821f5047eD6685aC25B30c0CFe9364E1f8d",
    collateralCoverageRatio: utils.parseEther(".4"), // 40%
    interestRate: utils.parseEther(".045"), // 4.5%
    chargeInterval: BigNumber.from(60 * 60 * 24), // daily (s * m * hr)
    burnRate: utils.parseEther(".15"), // 15%
    loanTerm: BigNumber.from(60 * 60 * 24 * 7 * 4), // 4 wk
    minLiquidity: utils.parseEther("1"),
    minDeposit: utils.parseEther(".05"), // 0.05 ETH,
    paymentFrequency: BigNumber.from(60 * 60 * 24 * 7), // 1 wk
  },
  {
    originalCollection: "0x889C1E6D4FEe51283c7ae2b2918b6ba1552E7FCB",
    collateralCoverageRatio: utils.parseEther(".4"), // 40%
    interestRate: utils.parseEther(".045"), // 4.5%
    chargeInterval: BigNumber.from(60 * 60 * 24), // daily (s * m * hr)
    burnRate: utils.parseEther(".15"), // 15%
    loanTerm: BigNumber.from(60 * 60 * 24 * 7 * 4), // 4 wk
    minLiquidity: utils.parseEther("1"),
    minDeposit: utils.parseEther(".05"), // 0.05 ETH,
    paymentFrequency: BigNumber.from(60 * 60 * 24 * 7), // 1 wk
  },
  {
    originalCollection: "0x0EcC55B840f672d6C844E4425a2A1DBD2b3791EE",
    collateralCoverageRatio: utils.parseEther(".4"), // 40%
    interestRate: utils.parseEther(".045"), // 4.5%
    chargeInterval: BigNumber.from(60 * 60 * 24), // daily (s * m * hr)
    burnRate: utils.parseEther(".15"), // 15%
    loanTerm: BigNumber.from(60 * 60 * 24 * 7 * 4), // 4 wk
    minLiquidity: utils.parseEther("1"),
    minDeposit: utils.parseEther(".05"), // 0.05 ETH,
    paymentFrequency: BigNumber.from(60 * 60 * 24 * 7), // 1 wk
  },
  {
    originalCollection: "0x5b6BeE649EdcA6b0550760737C67b4DfD7641107",
    collateralCoverageRatio: utils.parseEther(".4"), // 40%
    interestRate: utils.parseEther(".045"), // 4.5%
    chargeInterval: BigNumber.from(60 * 60 * 24), // daily (s * m * hr)
    burnRate: utils.parseEther(".15"), // 15%
    loanTerm: BigNumber.from(60 * 60 * 24 * 7 * 4), // 4 wk
    minLiquidity: utils.parseEther("1"),
    minDeposit: utils.parseEther(".05"), // 0.05 ETH,
    paymentFrequency: BigNumber.from(60 * 60 * 24 * 7), // 1 wk
  },
];

async function main() {
  const leverV1Factory = await ethers.getContractAt(
    "LeverV1Factory",
    "0xc3f345215cA77248Db844b8bA11B18eD0b23288B"
  );

  for (const pool of pools) {
    console.log("Creating pool");
    const createPoolTxn = await leverV1Factory.createPool(
      pool.originalCollection,
      pool.collateralCoverageRatio,
      pool.interestRate,
      pool.chargeInterval,
      pool.burnRate,
      pool.loanTerm,
      pool.minLiquidity,
      pool.minDeposit,
      pool.paymentFrequency
    );
    await createPoolTxn.wait();
    console.log(`${pool.originalCollection} created`);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
