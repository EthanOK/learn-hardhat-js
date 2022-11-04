const { expect, assert } = require("chai");
const { developmentChain, networkConfig } = require("../helper-hardhat-config");
const { ethers, network } = require("hardhat");

const addressC = "0xB0D04BcF6f82ce2C18d88a6995f61ae91bE0133f";
let sendValue = ethers.utils.parseEther("1");
let deployer;
let otherAccount;
let ethUsdPriceFeedAddress;

developmentChain.includes(network.name)
  ? describe.skip
  : describe("FundMe", function () {
      async function connectNet() {
        const signers = await ethers.getSigners();
        deployer = signers[0];
        otherAccount = signers[1];
        fundme = await ethers.getContractAt("FundMe", addressC);
        let chainId = network.config.chainId;
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
      }
      this.beforeEach(connectNet);

      it("Connet and return data --network", async function () {
        const version = await fundme.getVersion();
        assert.equal(version.toString(), "4");
        const priceFeed = await fundme.getPriceFeed();
        assert.equal(priceFeed, ethUsdPriceFeedAddress);
        console.log("getPriceFeed():" + priceFeed);
        console.log("ethUsdPriceFeed:" + ethUsdPriceFeedAddress);
      });

      it("Fund 1 ether --network", async function () {
        const fundemeConnect = await fundme.connect(deployer);
        const stratFundMeBalance =
          await fundemeConnect.getAddressToAmountFunded(deployer.address);
        const txResponse = await fundemeConnect.fund({ value: sendValue });
        await txResponse.wait(1);
        const endFundMeBalance = await fundemeConnect.getAddressToAmountFunded(
          deployer.address
        );
        assert.equal(
          endFundMeBalance.sub(stratFundMeBalance).toString(),
          sendValue.toString()
        );
      }).timeout(60000);
      it("Only owner withdraw", async function () {
        const fundemeConnectOwner = await fundme.connect(deployer);
        const txResponse = await fundemeConnectOwner.cheaperWithdraw();
        await txResponse.wait(1);
        const end_eth_contract = await ethers.provider.getBalance(
          fundemeConnectOwner.address
        );
        assert.equal(end_eth_contract, 0);
        const fundemeConnectOther = await fundme.connect(otherAccount);
        expect(await fundemeConnectOther.cheaperWithdraw()).to.be.reverted;
      }).timeout(180000);
    }).timeout(240000);
// npx hardhat test test/fundme_test_staging.js --network goerli
