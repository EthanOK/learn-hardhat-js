const { networkConfig, developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
const { ethers } = require("hardhat");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  // const ethUsdPriceFeed = networkConfig[chainId].ethUsdPriceFeed;
  // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  let ethUsdPriceFeedAddress;
  if (developmentChain.includes(network.name)) {
    // const ethUsdAggregator = await deployments.get("MockV3Aggregator");
    const ethUsdAggregator = await ethers.getContract("MockV3Aggregator");
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }
  console.log("MockV3Aggregator address:" + ethUsdPriceFeedAddress);
  const args = [ethUsdPriceFeedAddress];

  console.log("Deploying FundMe...");
  const contract = await deploy("FundMe", {
    from: deployer,
    args: args,
    log: true,
  });

  if (
    !developmentChain.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(contract.address, args);
  }
  log("FundMe deployed!");
  log("-----------------------");
};
module.exports.tags = ["all", "fundme"];

// npx hardhat deploy --tags all --network hardhat
// npx hardhat deploy --tags all --network goerli
