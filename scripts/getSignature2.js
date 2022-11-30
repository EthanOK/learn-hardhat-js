// https://learnblockchain.cn/article/2701
// eth_sign 签署任意数据 （信息和交易）

const {
  keccak256,
  toBuffer,
  ecrecover,
  ecsign,
  bufferToHex,
  toRpcSig,
  isValidSignature,
  pubToAddress,
  hashPersonalMessage,
} = require("ethereumjs-util");

const { ethers } = require("hardhat");

//   ECDSASignature {
//   v: number;
//   r: Buffer;
//   s: Buffer;
// }

async function getSignature() {
  const signerPvtKeyString = process.env.PRIVATE_KEY || "";

  const signerPvtKey = Buffer.from(signerPvtKeyString, "hex");

  let tokenId = 1;
  let account = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";

  let hashBuffer = generateHashBuffer(
    ["uint256", "address"],
    [tokenId, account]
  );
  console.log("hash data:" + bufferToHex(hashBuffer));

  // let hashMessage = hashPersonalMessage(hashBuffer);
  // console.log("hashMessage:" + bufferToHex(hashMessage));

  let _ECDSASignature = createSign(hashBuffer, signerPvtKey);

  let { v, r, s } = _ECDSASignature;

  // console.log(_ECDSASignature);
  console.log("isValidSignature:" + isValidSignature(v, r, s));
  // ECDSASignature => string
  let strSig = toRpcSig(v, r, s);
  console.log("strSig:" + strSig);

  let publickeyBuffer = ecrecover(hashBuffer, v, r, s);
  // Recovered public key
  let addressBuffer = pubToAddress(publickeyBuffer);
  console.log("address:" + bufferToHex(addressBuffer));
}

function createSign(hash, signerPvtKey) {
  return ecsign(hash, signerPvtKey);
}

function generateHashBuffer(typesArray, valueArray) {
  return keccak256(
    toBuffer(ethers.utils.defaultAbiCoder.encode(typesArray, valueArray))
  );
}

function serializeCoupon(coupon) {
  return {
    r: bufferToHex(coupon.r),
    s: bufferToHex(coupon.s),
    v: coupon.v,
  };
}

getSignature();

// console.log(signature);

// https://goerli.etherscan.io/address/0x6e7f9fccadfd34689a9542534c25475b5ffb7282#code

// node scripts/getSignature2.js
