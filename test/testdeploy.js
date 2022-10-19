const { expect, assert } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

// describe("Storage", function () {});
// describe("Storage", () => {});

describe("Storage", function () {
  async function deployOneYearLockFixture() {
    const [owner, otherAccount] = await ethers.getSigners();

    const Storage = await ethers.getContractFactory("Storage");
    const storage = await Storage.deploy(100);

    return { storage, owner, otherAccount };
  }

  describe("Depolyment", function () {
    it("Should start with a favorite number of 100", async function () {
      const { storage } = await loadFixture(deployOneYearLockFixture);
      const number = await storage.retrieve();
      assert.equal(number, 100);
    });

    it("Should updata when we call store", async function () {
      const { storage } = await loadFixture(deployOneYearLockFixture);
      const num = 200;
      const tx = await storage.store(num);
      // wait tx success
      await tx.wait();
      const number = await storage.retrieve();
      expect(number).to.equal(num);
    });
  });
});

// npx hardhat test test/testdeploy.js
