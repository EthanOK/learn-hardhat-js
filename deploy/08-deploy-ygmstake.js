const { networkConfig, developmentChain } = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");
const { ethers } = require("hardhat");
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  let usdtAddress;
  let ygmAddress;

  if (developmentChain.includes(network.name)) {
    const usdt = await ethers.getContract("USDToken");
    usdtAddress = usdt.address;
    const ygm = await ethers.getContract("YGMint");
    ygmAddress = ygm.address;
  }
  let createTime = 1669273800;
  let perPeriod = 300;
  const args = [ygmAddress, usdtAddress, deployer, createTime, perPeriod];

  console.log("Deploying YgmStaking...");
  const contract = await deploy("YgmStaking", {
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
  log("YgmStaking deployed!");
  log("-----------------------");
};
module.exports.tags = ["Stake", "YgmStaking"];

// npx hardhat deploy --tags all --network hardhat
// npx hardhat deploy --tags all --network goerli
