# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

If ethers.getContract is not a function  
You should commnd "npm install --save-dev @nomiclabs/hardhat-ethers@npm:hardhat-deploy-ethers ethers"

"npm install" install the package.json

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
npx hardhat compile
npx hardhat clean
npx hardhat verify --network goerli `contractAddress` `args`
npx hardhat blocknumber --network goerli
npx hardhat flatten ./contracts/YGToken.sol > ./flattens/flattenedYGToken.sol
npx hardhat deploy
```
