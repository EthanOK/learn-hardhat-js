const { verify } = require("../utils/verify");
const { ethers } = require("hardhat");

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_DAY_IN_SECS = 24 * 60 * 60;
  const unlockTime = currentTimestampInSeconds + ONE_DAY_IN_SECS;

  const Lock = await ethers.getContractFactory("Lock");

  console.log(`Deploying... `);
  const lock = await Lock.deploy(unlockTime);

  await lock.deployed();

  console.log(`Lock Contract deployed to ${lock.address}`);

  const args = [unlockTime];
  await verify(lock.address, args);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
