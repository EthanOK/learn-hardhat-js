const { ethers } = require("hardhat");
const fs = require("fs");
const abijson = "./abi/nftutils.json";

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(process.env.TBSC_URL);
  const data = fs.readFileSync(abijson, "UTF-8").toString();

  // 交互合约 new ethers.Contract(addressOrName, abi, providerOrSigner);
  let addressC = "0x90eAFf4169B2b9c55eA23Ab7392635DcF9d78985";
  let abi = JSON.parse(data);
  const nftutils = new ethers.Contract(addressC, abi, provider);
  try {
    // 0xF0D6CC43Ff6E35344120c27cB76Cc80E9706803c  13
    // 0x4f4D80c4063d275081EEa551d9467a1F49B542a4  error
    const total = await nftutils.totalSupply(
      "0x4f4D80c4063d275081EEa551d9467a1F49B542a4"
    );
    console.log(total);
  } catch {
    console.log("error");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/connecctNftUtils.js
// node scripts/connecctNftUtils.js
