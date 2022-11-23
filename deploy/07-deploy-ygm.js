const { developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  if (developmentChain.includes(network.name)) {
    //
  }

  console.log("Deploying YGMint...");

  const contract = await deploy("YGMint", {
    from: deployer,
    log: true,
  });

  if (
    !developmentChain.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY &&
    chainId != 97
  ) {
    await verify(contract.address, args);
  }

  log("YGMint deployed!");
  log("-----------------------");
};
module.exports.tags = ["Stake", "YGMint"];

// npx hardhat deploy --tags MyToken --network hardhat
