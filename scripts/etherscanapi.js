const fetch = require("node-fetch");
let maincontractaddress = "0xe3589AE55BbD7697C76c510a5335eB31d972A17E";
let tcontractaddress = "0x5aD9b20121F280DB32fFca6b0529f7E7b8Af331d";
const account = "0x0000000000000000000000000000000000000000";
// apikey=YourApiKeyToken
let data = `https://api.etherscan.io/api?module=account&action=tokennfttx&contractaddress=${maincontractaddress}&address=${account}&startblock=0&endblock=latest&sort=asc`;
let testdata = `https://api-goerli.etherscan.io/api?module=account&action=tokennfttx&contractaddress=${tcontractaddress}&address=${account}&startblock=0&endblock=latest&sort=asc`;

getJson();

async function getJson() {
  fetch(data)
    .then((response) => response.json())
    .then((json) => {
      // console.log(json);
      let result = json.result;

      if (json.status == "1" && result.length > 0) {
        let count = 0;

        for (const iterator of result) {
          if (iterator.from == account) {
            console.log("tokenID:" + iterator.tokenID);
            count++;
          }
        }
        console.log("total nft:" + count);
      }
    })
    .catch((err) => console.log("Request Failed", err));
}

/* {
    blockNumber: '7872584',
    timeStamp: '1667315640',
    hash: '0x77b92880c6ce269d7f9f3475e98a4b4ab532e356f3347a4fc82d7c6c2503661a',
    nonce: '95',
    blockHash: '0x63d496d48c6a350effe3901ee1430060dd1763d1dd7a4ac405928b48f55e01ad',
    from: '0x0000000000000000000000000000000000000000',
    contractAddress: '0x71ee06999f6d5f66aca3c12e45656362fd9d031f',
    to: '0x6278a1e803a76796a3a1f7f6344fe874ebfe94b2',
    tokenID: '1',
    tokenName: 'ERC721ATest',
    tokenSymbol: 'ERC721AT',
    tokenDecimal: '0',
    transactionIndex: '155',
    gas: '72932',
    gasPrice: '42290785670',
    gasUsed: '72932',
    cumulativeGasUsed: '26492099',
    input: 'deprecated',
    confirmations: '97010'
  }
 */
