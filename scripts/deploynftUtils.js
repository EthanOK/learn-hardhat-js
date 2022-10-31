const { ethers, run } = require("hardhat");

async function main() {
  const NFTUtils = await ethers.getContractFactory("NFTUtils");

  console.log(`Deploying... `);
  const utils = await NFTUtils.deploy();

  await utils.deployed();

  console.log(`Storage Contract deployed to ${utils.address}`);
  await verify(utils.address);
}

async function verify(contractAddress, args) {
  console.log(`Verifying... `);
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArgument: args,
    });
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("already verified!");
    } else {
      console.log(e);
    }
  }
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/deploynftUtils.js
// npx hardhat run scripts/deploynftUtils.js --network tbsc
// npx hardhat verify --network tbsc 0x84C6967634E55d1742b7693D17aa254d12ba79A5
