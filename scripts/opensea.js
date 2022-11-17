// const { OpenSeaSDK, Network } = require("opensea-js");
const { ethers } = require("hardhat");
// This example provider won't let you make transactions, only read-only calls:
const provider = new ethers.providers.JsonRpcProvider(process.env.GOERLI_URL);

const account = "0x6278a1e803a76796a3a1f7f6344fe874ebfe94b2";
use_ethers_getData();
/* const openseaSDK = new OpenSeaSDK(provider, {
  networkName: Network.Main,
  apiKey: YOUR_API_KEY,
});
 */

async function use_ethers_getData() {
  const network = await provider.getNetwork();
  console.log(network);
  // {
  //   name: 'goerli',
  //   chainId: 5,
  //   ensAddress: '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e',
  //   _defaultProvider: [Function: func] { renetwork: [Function (anonymous)] }
  // }
  const balance = await provider.getBalance(account);
  console.log("balance:" + balance.toString());
}

// npm install --save opensea-js
