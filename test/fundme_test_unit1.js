const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
let sendValue = ethers.utils.parseEther("1");

describe("FundMe", async function () {
  let fundMe;
  let deployer;
  let mockV3Aggregator;
  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer;
    // deploy
    await deployments.fixture(["all"]);
    // if ethers.getContract is not a function
    // npx install -D @nomiclabs/hardhat-ethers@npm:hardhat-deploy-ethers
    mockV3Aggregator = await ethers.getContract("MockV3Aggregator", deployer);
    fundMe = await ethers.getContract("FundMe", deployer);
  });

  describe("Constructor", function () {
    it("sets the aggregator address correctly", async function () {
      const priceFeed = await fundMe.getPriceFeed();
      assert.equal(priceFeed, mockV3Aggregator.address);
    });
  });
});

// npx hardhat test test/fundme_test_unit1.js
// npx hardhat test --grep "from a single funder"
