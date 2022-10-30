const { ethers } = require("hardhat");
const fetch = require("node-fetch");
const fs = require("fs");

const getPath = "./IPFS/json";
let contract;

async function connectionContract() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env.ALCHEMY_ETHER_URL
  );

  let addressC = "0x3e6046b4d127179f0a421f3148b43cf52c08fc41";
  let interface721abi = [
    {
      inputs: [
        {
          internalType: "uint256",
          name: "tokenId",
          type: "uint256",
        },
      ],
      name: "tokenURI",
      outputs: [
        {
          internalType: "string",
          name: "",
          type: "string",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [],
      name: "totalSupply",
      outputs: [
        {
          internalType: "uint256",
          name: "",
          type: "uint256",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
  ];
  contract = new ethers.Contract(addressC, interface721abi, provider);
}

async function getJson(total) {
  if (total < 1) {
    console.log("return 0");
    return 0;
  }
  let checkDir = fs.existsSync(getPath);
  if (!checkDir) {
    fs.mkdirSync(getPath);
  }
  // let total = await contract.totalSupply();
  // console.log(total);

  // get ipfs hash
  let URL = await contract.tokenURI(1);
  // QmVbZhfYHDyttyPjHQokVHVPYe7Bd5RdUrhxHoE6QimyYs
  let ipfsHash = URL.substr(7, 46);

  for (let index = 1; index <= total; index++) {
    let ipfsURL = ipfsHash + "/" + index;
    console.log(ipfsURL);
    await getJsonUseIpfs(ipfsURL, index);
  }
}
async function getJsonUseIpfs(ipfsURL, index) {
  fetch(`https://ipfs.io/ipfs/${ipfsURL}`)
    .then((response) => response.json())
    .then((json) => {
      console.log(json);
      fs.writeFileSync(
        `${getPath}/${index}.json`,
        JSON.stringify(json, null, 2)
      );
    })
    .catch((err) => console.log("Request Failed", err));
}
async function main() {
  await connectionContract();
  await getJson(50);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// node scripts/getIPFS.js
