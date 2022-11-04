const { expect, assert } = require("chai");
const { developmentChain, networkConfig } = require("../helper-hardhat-config");
const { ethers, network } = require("hardhat");

const addressC = "0xB0D04BcF6f82ce2C18d88a6995f61ae91bE0133f";
let sendValue = ethers.utils.parseEther("1");
let deployer;
let ethUsdPriceFeedAddress;

developmentChain.includes(network.name)
  ? describe.skip
  : describe("FundMe", function () {
      async function connect() {
        deployer = await ethers.getSigners()[0];
        fundme = await ethers.getContractAt("FundMe", addressC);
        let chainId = network.config.chainId;
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
      }
      this.beforeEach(connect);

      it("fund and withdraw --network", async function () {
        const version = await fundme.getVersion();
        assert.equal(version.toString(), "4");
        const priceFeed = await fundme.getPriceFeed();
        assert.equal(priceFeed, ethUsdPriceFeedAddress);
        console.log("getPriceFeed():" + priceFeed);
        console.log("ethUsdPriceFeed:" + ethUsdPriceFeedAddress);
      });
    });
// npx hardhat test test/fundme_test_staging.js --network goerli
