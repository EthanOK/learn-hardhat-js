const { ethers } = require("hardhat");
async function sendTransaction() {
  const [owner] = await ethers.getSigners();
  console.log(owner);
  let wallet = new ethers.Wallet(process.env.PRIVATE_KEY);

  console.log(wallet.address);

  // All properties are optional
  let transaction = {
    to: "0x53188E798f2657576c9de8905478F46ac2f24b67",
    value: ethers.utils.parseEther("1.0"),
    data: "0x",
    // 这可确保无法在不同网络上重复广播
    chainId: 12,
  };

  let signPromise = wallet.sign(transaction);

  signPromise.then((signedTransaction) => {
    console.log(signedTransaction);

    // 现在可以将其发送到以太坊网络
    let provider = ethers.getDefaultProvider();
    provider.sendTransaction(signedTransaction).then((tx) => {
      console.log(tx);
    });
  });
}
sendTransaction();
