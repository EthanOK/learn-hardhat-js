const { ethers } = require("hardhat");

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY);

// 签名二进制信息
// https://learnblockchain.cn/docs/ethers.js/api-wallet.html#id14
// https://learnblockchain.cn/docs/ethers.js/api-utils.html#solidity
// keccak256(abi.encodePacked(a, b)) == utils.solidityKeccak256(types, values)
let tokenId = 1;
let account = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
let message = ethers.utils.solidityKeccak256(
  ["uint256", "address"],
  [tokenId, account]
);
console.log(`tokenId: ${tokenId}`);
console.log(`account: ${account}`);
console.log("utils.solidityKeccak256(a, b):", message);
// console.log(ethers.utils.arrayify(message));
const signature = wallet.signMessage(ethers.utils.arrayify(message));

signature.then((sign) => {
  console.log("signature:", sign);
});
// console.log(signature);

// https://goerli.etherscan.io/address/0x6e7f9fccadfd34689a9542534c25475b5ffb7282#code

// node scripts/getSignature.js
