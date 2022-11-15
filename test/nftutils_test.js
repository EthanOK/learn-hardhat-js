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
    let txResponse1 = await nftutils.setContactDatas(
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

  describe("Test WhiteList Set Contact Datas", function () {
    it("onlyOwner Set Contact Datas", async function () {
      let txResponse = await nftutils.setContactDatas(
        mytoken.address,
        verifier.address,
        sourceAccount.address
      );
      await txResponse.wait(1);
      [v, s] = await nftutils.getContractData(mytoken.address);
      assert.equal(v, verifier.address);
      assert.equal(s, sourceAccount.address);
    });

    it("otherAccount Set Contact Datas will be reverted", async function () {
      nftutils = nftutils.connect(verifier);

      await expect(
        nftutils.setContactDatas(
          mytoken.address,
          verifier.address,
          sourceAccount.address
        )
      ).to.be.reverted;
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
      let timestamp = Math.floor(new Date().getTime() / 1000) - 2;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mytoken.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata);
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
  });
});
function getSignature(hashdata) {
  let binaryData = ethers.utils.arrayify(hashdata);
  let signature = verifier.signMessage(binaryData);
  return signature;
}
// npx hardhat test test/nftutils_test.js
// npx hardhat test --grep "otherAccount Set"
