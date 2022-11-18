const { network } = require("hardhat");
const {
  developmentChain,
  Decimals,
  InitialAnswer,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  // if(chainId=="31337")
  if (developmentChain.includes(network.name)) {
    log("Local network detected! Deploying mocks...");
    console.log("Deploying MockV3Aggregator...");
    await deploy("MockV3Aggregator", {
      from: deployer,
      args: [Decimals, InitialAnswer],
      log: true,
    });
    log("Mocks deployed!");
    log("-----------------------");
  }
};

module.exports.tags = ["all", "mocks", "NFTUtils"];

// npx hardhat deploy --tags mocks
