const { expect, assert } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { Decimals, InitialAnswer } = require("../helper-hardhat-config");
const { ethers } = require("hardhat");
// describe("Storage", function () {});
// describe("Storage", () => {});
let sendValue = ethers.utils.parseEther("1");

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

  describe("fund", function () {
    it("Fails if you don't send enough ETH", async function () {
      const { fundme } = await loadFixture(deployOneYearLockFixture);
      await expect(fundme.fund()).to.be.revertedWith(
        "You need to spend more ETH!"
      );
    });

    it("Updata the mount funded data", async function () {
      const { fundme, owner } = await loadFixture(deployOneYearLockFixture);
      await fundme.fund({ value: sendValue });
      let response = await fundme.getAddressToAmountFunded(owner.address);
      assert.equal(sendValue.toString(), response.toString());
    });

    it("Adds funder to array of funders", async function () {
      const { fundme, owner } = await loadFixture(deployOneYearLockFixture);
      await fundme.fund({ value: sendValue });
      let addr = await fundme.getFunder(0);
      assert.equal(owner.address, addr);
    });
  });

  describe("withdraw", function () {
    it("Withdraw ETH from a single funder", async function () {
      const { owner, fundme } = await loadFixture(deployOneYearLockFixture);
      await fundme.fund({ value: sendValue });

      const stratOwnerBalance = await ethers.provider.getBalance(owner.address);
      const stratFundMeBalance = await ethers.provider.getBalance(
        fundme.address
      );

      const transactionResponse = await fundme.withdraw();
      // wait( [ confirms = 1 ] )
      // 一旦交易以确认区块被包含在链中，则解析为 TransactionReceipt
      const transactionReceipt = await transactionResponse.wait(1);
      // calculate gas cost
      const { gasUsed, effectiveGasPrice } = transactionReceipt;
      const gascost = gasUsed.mul(effectiveGasPrice);
      const endOwnerBalance = await ethers.provider.getBalance(owner.address);
      const endFundMeBalance = await ethers.provider.getBalance(fundme.address);

      // assert
      assert.equal(endFundMeBalance.toString(), "0");
      assert.equal(
        stratOwnerBalance.add(stratFundMeBalance).toString(),
        endOwnerBalance.add(gascost).toString()
      );
    });

    it("Allows us to withdraw with multiple funders", async function () {
      const { owner, fundme } = await loadFixture(deployOneYearLockFixture);
      const signers = await ethers.getSigners();
      for (const signer of signers) {
        const fundmeC = fundme.connect(signer);
        await fundmeC.fund({ value: sendValue });
      }

      for (const signer of signers) {
        expect(
          await fundme.getAddressToAmountFunded(signer.address)
        ).to.be.equal(sendValue);
      }

      const stratOwnerBalance = await ethers.provider.getBalance(owner.address);
      const stratFundMeBalance = await ethers.provider.getBalance(
        fundme.address
      );

      const transactionResponse = await fundme.withdraw();
      // wait( [ confirms = 1 ] )
      // 一旦交易以确认区块被包含在链中，则解析为 TransactionReceipt
      const transactionReceipt = await transactionResponse.wait(1);
      // calculate gas cost
      const { gasUsed, effectiveGasPrice } = transactionReceipt;
      const gascost = gasUsed.mul(effectiveGasPrice);

      const endOwnerBalance = await ethers.provider.getBalance(owner.address);
      const endFundMeBalance = await ethers.provider.getBalance(fundme.address);

      // assert
      assert.equal(endFundMeBalance, 0);
      assert.equal(
        stratOwnerBalance.add(stratFundMeBalance).toString(),
        endOwnerBalance.add(gascost).toString()
      );

      for (const signer of signers) {
        if (signer.address == owner.address) continue;
        expect(
          await fundme.getAddressToAmountFunded(signer.address)
        ).to.be.equal(0);
      }
    });

    it("Only allows the owner to withdraw us", async function () {
      const { owner, fundme, otherAccount } = await loadFixture(
        deployOneYearLockFixture
      );
      const fundmeOther = fundme.connect(otherAccount);
      await expect(fundmeOther.withdraw()).to.be.reverted;
    });
  });
});

// npx hardhat test test/fundme_test.js
// npx hardhat test --grep "from a single funder"
