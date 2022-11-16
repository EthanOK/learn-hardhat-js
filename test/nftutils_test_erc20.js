const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
let value = ethers.utils.parseEther("1000");
let owner, sourceAccount, verifier, receiver;

describe("NFTUtils", async function () {
  let mytoken;
  let nftutils;
  let deployer;

  beforeEach(async function () {
    [owner, sourceAccount, verifier, receiver] = await ethers.getSigners();
    deployer = (await getNamedAccounts()).deployer;
    // deploy
    await deployments.fixture(["NFTUtils"]);
    // if ethers.getContract is not a function
    // npx install -D @nomiclabs/hardhat-ethers@npm:hardhat-deploy-ethers
    mytoken = await ethers.getContract("MyToken", deployer);
    nftutils = await ethers.getContract("NFTUtils", deployer);
    // deployer(owner) mint
    let txResponse = await mytoken.mint(sourceAccount.address, value);
    await txResponse.wait(1);

    // sourceAccount  approve nftutils value
    mytoken = mytoken.connect(sourceAccount);
    let txResponse0 = await mytoken.approve(nftutils.address, value);
    await txResponse0.wait(1);

    // deployer setContactDatas
    let txResponse1 = await nftutils.setContactData(
      mytoken.address,
      verifier.address,
      sourceAccount.address
    );
    await txResponse1.wait(1);
  });

  describe("Constructor", function () {
    it("name symbol decimals", async function () {
      let [name_, symbol_, decimals_] = await nftutils.nameSyDecERC20(
        mytoken.address
      );
      assert.equal(await mytoken.name(), name_);
      assert.equal(await mytoken.symbol(), symbol_);
      assert.equal(await mytoken.decimals(), decimals_);
    });

    it("totalSupply ERC20", async function () {
      let total = await nftutils.totalSupplyERC20(mytoken.address);
      let total_ = await mytoken.totalSupply();
      assert.equal(total_.toString(), total.toString());
      assert.equal(total_.toString(), value.add(value).toString());
    });
    it("allowance(sourceAccount, nftutils) 1000 ether ERC20", async function () {
      let total = await nftutils.allowanceERC20(
        mytoken.address,
        sourceAccount.address,
        nftutils.address
      );
      let total_ = await mytoken.allowance(
        sourceAccount.address,
        nftutils.address
      );
      assert.equal(total_.toString(), total.toString());
      assert.equal(total_.toString(), value.toString());
    });

    it("balanceOf ERC20", async function () {
      let value0 = await nftutils.balanceOfERC20(mytoken.address, deployer);
      let value1 = await mytoken.balanceOf(deployer);
      let value2 = await mytoken.balanceOf(sourceAccount.address);
      assert.equal(value0.toString(), value.toString());
      assert.equal(value0.toString(), value1.toString());
      expect(value.toString()).to.be.equal(value2.toString());
    });
  });

  describe("Test WhiteList Set Contact Data", function () {
    it("onlyOwner Set Contact Data", async function () {
      let txResponse = await nftutils.setContactData(
        mytoken.address,
        verifier.address,
        sourceAccount.address
      );
      await txResponse.wait(1);
      [v, s] = await nftutils.getContractData(mytoken.address);
      assert.equal(v, verifier.address);
      assert.equal(s, sourceAccount.address);
    });

    it("otherAccount Set Contact Data will be reverted", async function () {
      nftutils = nftutils.connect(verifier);

      await expect(
        nftutils.setContactData(
          mytoken.address,
          verifier.address,
          sourceAccount.address
        )
      ).to.be.reverted;
    });
  });
  describe("Test WhiteList get Contract Data", function () {
    it("get Contract Data", async function () {
      [v, s] = await nftutils.getContractData(mytoken.address);
      assert.equal(v, verifier.address);
      assert.equal(s, sourceAccount.address);
    });
  });
  /* 
    function claimERC20(
        address contactAddr,
        address account,
        uint256 amount,
        uint256 total_account,
        uint256 timestamp,
        bytes calldata signature
    ) external whenNotPaused nonReentrant returns (bool);
    */
  describe("Test WhiteList claimERC20", function () {
    it("claimERC20 success", async function () {
      let amount = ethers.utils.parseEther("100");
      let amount1 = ethers.utils.parseEther("110");
      let total = ethers.utils.parseEther("200");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);
      let balanceOfsourceAccountstart = await mytoken.balanceOf(
        sourceAccount.address
      );

      let balanceOfreceiverstart = await mytoken.balanceOf(receiver.address);
      // claimERC20
      let txResponse = await nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await txResponse.wait(1);

      let balanceOfsourceAccountend = await mytoken.balanceOf(
        sourceAccount.address
      );
      let balanceOfReceiverend = await mytoken.balanceOf(receiver.address);

      assert.equal(
        balanceOfsourceAccountstart.sub(balanceOfsourceAccountend).toString(),
        balanceOfReceiverend.sub(balanceOfreceiverstart).toString()
      );
      assert.equal(
        balanceOfsourceAccountstart.sub(balanceOfsourceAccountend).toString(),
        amount.toString()
      );
    });
    it("signer is not verifier, claimERC20 will be reverted", async function () {
      let amount = ethers.utils.parseEther("100");
      let total = ethers.utils.parseEther("200");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, owner);
      // console.log("signature:" + signature);

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await expect(txResponse).to.be.revertedWith("Invalid signature");
    });
    it("change some parameter(be signed), claimERC20 will be reverted", async function () {
      let amount = ethers.utils.parseEther("100");
      let total = ethers.utils.parseEther("200");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      let changeAmount = ethers.utils.parseEther("180");

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        changeAmount,
        total,
        timestamp,
        signature
      );
      await expect(txResponse).to.be.revertedWith("Invalid signature");
    });
    it("block.timestamp - timestamp > 180, claimERC20 will be reverted", async function () {
      let amount = ethers.utils.parseEther("100");
      let total = ethers.utils.parseEther("200");
      // block.timestamp ~= Math.floor(new Date().getTime() / 1000)
      // Should: 0 <= interval <= 180
      let interval = 200;
      let timestamp = Math.floor(new Date().getTime() / 1000) - interval;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await expect(txResponse).to.be.revertedWith("expiration time");
    });
  });
  describe("Test WhiteList get SumClaimedERC20", function () {
    it("get SumClaimedERC20", async function () {
      let amount = ethers.utils.parseEther("100");
      let total = ethers.utils.parseEther("200");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);

      // claimERC20
      let txResponse = await nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await txResponse.wait(1);
      let total0 = await nftutils.getSumClaimedERC20(
        mytoken.address,
        receiver.address
      );
      assert.equal(total0.toString(), amount.toString());

      // add amount
      let amountAdd = ethers.utils.parseEther("80");
      let hashdata1 = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amountAdd, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature1 = await getSignature(hashdata1, verifier);

      // claimERC20
      let txResponse1 = await nftutils.claimERC20(
        mytoken.address,
        receiver.address,
        amountAdd,
        total,
        timestamp,
        signature1
      );
      await txResponse1.wait(1);
      let total1 = await nftutils.getSumClaimedERC20(
        mytoken.address,
        receiver.address
      );
      assert.equal(total1.toString(), amount.add(amountAdd).toString());
    });
  });
});

function getSignature(hashdata, signer) {
  let binaryData = ethers.utils.arrayify(hashdata);
  let signature = signer.signMessage(binaryData);
  return signature;
}
// npx hardhat test test/nftutils_test.js
// npx hardhat test --grep "SumClaimedERC20"
