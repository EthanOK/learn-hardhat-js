const { ethers } = require("hardhat");

async function sendtx() {
  provider = new ethers.providers.JsonRpcProvider();
  pk = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

  wallet = new ethers.Wallet(pk);

  // Wallet connected to a provider
  wallet = await wallet.connect(provider);

  // Signing a message
  await wallet.signMessage("Hello World");

  txdata = {
    to: "0x8ba1f109551bD432803012645Ac136ddd64DBA72",
    value: ethers.utils.parseEther("1.0"),
  };

  // Signing a transaction
  hashdata = await wallet.signTransaction(txdata);
  console.log("signTransaction hashdata:" + hashdata);

  count = await wallet.getTransactionCount();
  console.log("TransactionCount:" + count);

  // Sending ether
  TResponse = await wallet.sendTransaction(txdata);
  await TResponse.wait();

  addr = await wallet.getAddress();
  console.log("addr: " + addr);
  balance = await provider.getBalance(addr);
  console.log("send balance: " + balance);

  balance = await provider.getBalance(
    "0x8ba1f109551bD432803012645Ac136ddd64DBA72"
  );
  console.log("receive balance: " + balance);

  count = await wallet.getTransactionCount();
  console.log("TransactionCount:" + count);
}
sendtx();
