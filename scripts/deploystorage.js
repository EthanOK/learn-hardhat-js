const { ethers, run } = require("hardhat");

async function main() {
  const Storage = await ethers.getContractFactory("Storage");

  console.log(`Deploying... `);
  const storage = await Storage.deploy(100);

  await storage.deployed();

  console.log(`Storage Contract deployed to ${storage.address}`);
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

// npx hardhat run scripts/deploystorage.js
// npx hardhat run scripts/deploystorage.js --network tbsc
// npx hardhat verify --network tbsc 0x3116e77553Fc3aeFDC1F9E981929F554bC615711 100
