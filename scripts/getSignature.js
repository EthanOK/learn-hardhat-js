const { ethers } = require("hardhat");

// const provider = new ethers.providers.JsonRpcProvider(
//   process.env.ALCHEMY_GOERLI_URL
// );

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY);

// // 签名文本消息
// let str = "Hello";
// let signPromise = wallet.signMessage(str);

// console.log(signPromise);

// signPromise.then((signature) => {
//   // Flat-format
//   console.log(signature);

//   // Expanded-format
//   // console.log(ethers.utils.splitSignature(signature));
// });

// 签名 msg.data
let message = ethers.utils.solidityKeccak256(
  ["uint256", "address"],
  [5, "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2"]
);
console.log(message);
console.log(ethers.utils.arrayify(message));
const signature = wallet.signMessage(ethers.utils.arrayify(message));
console.log(signature);

// https://goerli.etherscan.io/address/0x6e7f9fccadfd34689a9542534c25475b5ffb7282#code

// node scripts/getSignature.js
