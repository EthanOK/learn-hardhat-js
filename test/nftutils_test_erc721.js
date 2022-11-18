const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
let amount = 10;
let owner, sourceAccount, verifier, receiver;

describe("NFTUtils", async function () {
  let mynft;
  let mytoken;
  let nftutils;
  let deployer;
  let mockV3Aggregator;
  beforeEach(async function () {
    [owner, sourceAccount, verifier, receiver] = await ethers.getSigners();
    deployer = (await getNamedAccounts()).deployer;
    // deploy
    await deployments.fixture(["NFTUtils"]);
    mockV3Aggregator = await ethers.getContract("MockV3Aggregator");
    mytoken = await ethers.getContract("MyToken", deployer);
    mynft = await ethers.getContract("MyNFT", deployer);
    nftutils = await ethers.getContract("NFTUtils", deployer);
    // deployer(owner)  have 10 nft
    // safeMintBatch sourceAccount 10 nft
    let txResponse = await mynft.safeMintBatch(sourceAccount.address, amount);
    await txResponse.wait(1);

    mynft = mynft.connect(sourceAccount);
    let txResponse0 = await mynft.setApprovalForAll(nftutils.address, true);
    await txResponse0.wait(1);

    // deployer setContactDatas
    let txResponse1 = await nftutils.setContactData(
      mynft.address,
      verifier.address,
      sourceAccount.address
    );
    await txResponse1.wait(1);
  });
  describe("QueryNFTData", function () {
    it("name symbol", async function () {
      let [name_, symbol_] = await nftutils.nameAndsymbol(mynft.address);
      assert.equal(await mynft.name(), name_);
      assert.equal(await mynft.symbol(), symbol_);
      assert.equal("MyNFT", name_);
      assert.equal("MNT", symbol_);
    });
    it("totalSupply", async function () {
      let total = await nftutils.totalSupply(mynft.address);
      let total_ = await mynft.totalSupply();
      assert.equal(total_.toString(), total.toString());
      assert.equal(total_.toString(), "20");
    });
    it("balanceOf", async function () {
      let value0 = await nftutils.balanceOf(mynft.address, deployer);
      let value1 = await mynft.balanceOf(deployer);
      let value2 = await mynft.balanceOf(sourceAccount.address);
      assert.equal(value0.toString(), value1.toString());
      assert.equal(value1.toString(), value2.toString());
      expect(value2.toString()).to.be.equal("10");
    });
    it("tokenURI", async function () {
      let tokenId = 10;
      let uri0 = await nftutils.tokenURI(mynft.address, tokenId);
      let uri1 = await mynft.tokenURI(tokenId);
      let uri2 = await mynft.tokenURI(15);
      assert.equal(uri0, uri1);
      assert.notEqual(uri1, uri2);
    });
    it("ownerOf", async function () {
      let tokenId = 10;
      let account0 = await nftutils.ownerOf(mynft.address, tokenId);
      let account1 = await mynft.ownerOf(tokenId);
      assert.equal(account0, account1);
    });
    it("isApprovedForAll", async function () {
      let result0 = await nftutils.isApprovedForAll(
        mynft.address,
        sourceAccount.address,
        nftutils.address
      );
      let result1 = await mynft.isApprovedForAll(
        sourceAccount.address,
        nftutils.address
      );
      assert.equal(result0, result1);
      assert.equal(result0, true);
    });
    it("tokenId Is Account", async function () {
      let tokenId = 15;
      let reusult = await nftutils.tokenIdIsAccount(
        mynft.address,
        tokenId,
        sourceAccount.address
      );
      let account = await mynft.ownerOf(tokenId);
      assert.equal(account, sourceAccount.address);
      assert.equal(reusult, true);

      let account1 = await mynft.ownerOf(10);
      assert.notEqual(account, account1);
    });
    it("getApproved", async function () {
      let tokenId = 10;
      let address0 = await nftutils.getApproved(mynft.address, tokenId);
      let address1 = await mynft.getApproved(tokenId);
      assert.equal(address0, address1);
      assert.equal(address0, 0);

      // approve(address to, uint256 tokenId) sourceAccount have tokenId 11-20
      mynft = mynft.connect(sourceAccount);
      let txr = mynft.approve(owner.address, tokenId);
      expect(txr).to.be.revertedWith("ERC721: approval to current owner");
      let txResponse = await mynft.approve(owner.address, 15);
      txResponse.wait(1);

      let address2 = await mynft.getApproved(15);
      assert.equal(address2, owner.address);
    });
    // IERC721: 0x80ac58cd IERC721Enumerable：0x780e9d63
    it("supportsInterface(address, bytes4)  IERC721 IERC721Enumerable", async function () {
      let result0 = await nftutils.getSupportsInterface(
        mynft.address,
        0x80ac58cd
      );
      let result1 = await nftutils.getSupportsInterface(
        mynft.address,
        0x780e9d63
      );
      assert.equal(result0, result1);
      assert.equal(result0, true);
    });
    it("tokenOfOwnerByIndex", async function () {
      let tokenid = await nftutils.tokenOfOwnerByIndex(
        mynft.address,
        owner.address,
        0
      );
      let tokenid2 = await nftutils.tokenOfOwnerByIndex(
        mynft.address,
        sourceAccount.address,
        0
      );

      assert.equal(tokenid.toString(), 1);
      assert.equal(tokenid2.toString(), 11);
    });
    it("tokenByIndex", async function () {
      let tokenid = await nftutils.tokenByIndex(mynft.address, 0);
      let tokenid2 = await nftutils.tokenByIndex(mynft.address, 14);

      assert.equal(tokenid.toString(), 1);
      assert.equal(tokenid2.toString(), 15);
    });
    it("contract Is ERC721", async function () {
      let result0 = await nftutils.contractIsERC721(mynft.address);
      let result1 = await nftutils.contractIsERC721(mytoken.address);
      assert.equal(result0, true);
      assert.equal(result1, false);
    });
    it("getContractOwner", async function () {
      let address0 = await nftutils.getContractOwner(mynft.address);
      let address1 = await nftutils.getContractOwner(mytoken.address);
      assert.equal(address0, address1);
      assert.equal(address0, owner.address);
      try {
        await nftutils.getContractOwner(mockV3Aggregator.address);
      } catch (error) {
        assert.equal(error.reason, "external call failed");
      }
    });
  });

  describe("Test WhiteList Set Contact Data", function () {
    it("onlyOwner Set Contact Data", async function () {
      let txResponse = await nftutils.setContactData(
        mynft.address,
        verifier.address,
        sourceAccount.address
      );
      await txResponse.wait(1);
      [v, s] = await nftutils.getContractData(mynft.address);
      assert.equal(v, verifier.address);
      assert.equal(s, sourceAccount.address);
    });

    it("otherAccount Set Contact Data will be reverted", async function () {
      nftutils = nftutils.connect(verifier);

      await expect(
        nftutils.setContactData(
          mynft.address,
          verifier.address,
          sourceAccount.address
        )
      ).to.be.reverted;
    });
  });
  describe("Test WhiteList get Contract Data", function () {
    it("get Contract Data", async function () {
      [v, s] = await nftutils.getContractData(mynft.address);
      assert.equal(v, verifier.address);
      assert.equal(s, sourceAccount.address);
    });
  });
  /* 
    function claimERC721(
        address contactAddr,
        address account,
        uint256 tokenId,
        uint256 timestamp,
        bytes calldata signature
    ) external nonReentrant returns (bool) ;
    */
  describe("Test WhiteList claimERC721", function () {
    it("claimERC721 success", async function () {
      let result = await mynft.isApprovedForAll(
        sourceAccount.address,
        nftutils.address
      );
      assert.equal(result, true);
      // sourceAccount.address huve 11 - 20
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      let tokenId = 15;
      let account = await mynft.ownerOf(tokenId);
      assert.equal(account, sourceAccount.address);

      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256"],
        [mynft.address, receiver.address, tokenId, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      let txResponse = await nftutils.claimERC721(
        mynft.address,
        receiver.address,
        tokenId,
        timestamp,
        signature
      );
      await txResponse.wait(1);
      let account1 = await mynft.ownerOf(tokenId);
      assert.equal(account1, receiver.address);
    });
    /* it("signer is not verifier, claimERC20 will be reverted", async function () {
      let amount = ethers.utils.parseEther("100");
      let total = ethers.utils.parseEther("200");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mynft.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, owner);
      // console.log("signature:" + signature);

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mynft.address,
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
        [mynft.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      let changeAmount = ethers.utils.parseEther("180");

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mynft.address,
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
        [mynft.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mynft.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await expect(txResponse).to.be.revertedWith("expiration time");
    });
    it("allowance(sourceAccount, nftutils) 1000 and receiver claim 1100, claimERC20 will be reverted", async function () {
      let amount = ethers.utils.parseEther("1100");
      let total = ethers.utils.parseEther("2000");
      let timestamp = Math.floor(new Date().getTime() / 1000) - 5;
      // console.log("timestamp:" + timestamp);
      let hashdata = ethers.utils.solidityKeccak256(
        ["address", "address", "uint256", "uint256", "uint256"],
        [mynft.address, receiver.address, amount, total, timestamp]
      );
      // console.log("hashdata:" + hashdata);
      let signature = await getSignature(hashdata, verifier);
      // console.log("signature:" + signature);

      // claimERC20
      let txResponse = nftutils.claimERC20(
        mynft.address,
        receiver.address,
        amount,
        total,
        timestamp,
        signature
      );
      await expect(txResponse).to.be.revertedWith(
        "ERC20: insufficient allowance"
      );
    }); */
  });
});

function getSignature(hashdata, signer) {
  let binaryData = ethers.utils.arrayify(hashdata);
  let signature = signer.signMessage(binaryData);
  return signature;
}
// npx hardhat test test/nftutils_test_erc721.js
// npx hardhat test --grep "SumClaimedERC20"
