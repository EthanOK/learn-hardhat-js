const { ethers } = require("hardhat");
let timestamp = new Date().getTime();
//console.log(timestamp);
let blocktimestamp = Math.floor(timestamp / 1000);
console.log(blocktimestamp);

getSignature();

async function getSignature() {
  const [owner, signer] = await ethers.getSigners();
  let tokenId = 5;

  let contractAdrr = "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9";
  let account = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
  let message = ethers.utils.solidityKeccak256(
    ["address", "address", "uint256", "uint256"],
    [contractAdrr, account, tokenId, blocktimestamp]
  );
  console.log("keccak256(abi.encodePacked(a, b)):", message);
  // console.log(ethers.utils.arrayify(message));
  let binaryData = ethers.utils.arrayify(message);
  const signature = signer.signMessage(binaryData);
  console.log("signer:" + signer.address);
  signature.then((sign) => {
    console.log("signature:", sign);
  });
}
