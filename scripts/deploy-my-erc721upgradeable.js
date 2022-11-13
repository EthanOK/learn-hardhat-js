// npx hardhat run scripts/deploy-my-erc721upgradeable.js
// --network goerli 0xBDFa72a86B2306DB16866c87b88E1C11FdBf9469
const { ethers, upgrades } = require("hardhat");

async function main() {
  const MyERC721Upgradeable = await ethers.getContractFactory(
    "MyERC721Upgradeable"
  );

  const myProxy = await upgrades.deployProxy(MyERC721Upgradeable);

  await myProxy.deployed();
  console.log("myProxy deployed to:", myProxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
