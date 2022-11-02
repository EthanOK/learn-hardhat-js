const { expect, assert } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { Decimals, InitialAnswer } = require("../helper-hardhat-config");
// describe("Storage", function () {});
// describe("Storage", () => {});

describe("FundMe", function () {
  async function deployOneYearLockFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const MockV3Aggregator = await ethers.getContractFactory(
      "MockV3Aggregator"
    );
    const mockV3Aggregator = await MockV3Aggregator.deploy(
      Decimals,
      InitialAnswer
    );

    const FundMe = await ethers.getContractFactory("FundMe");
    const fundme = await FundMe.deploy(mockV3Aggregator.address);

    return { mockV3Aggregator, fundme, owner, otherAccount };
  }

  describe("Constructor", function () {
    it("sets the aggregator address correctly", async function () {
      const { mockV3Aggregator, fundme } = await loadFixture(
        deployOneYearLockFixture
      );
      const priceFeed = await fundme.getPriceFeed();
      assert.equal(priceFeed, mockV3Aggregator.address);
    });
  });
});

// npx hardhat test test/fundme_test.js
