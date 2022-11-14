// function deploy() {
//   console.log("Hi");
// }
// module.exports.default = deploy;

// module.exports = async (hre) => {
//   const { getNamedAccounts, deployments } = hre;
// };

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  console.log(`deployer: ${deployer}`);
  console.log(`chainId: ${chainId}`);
  console.log("------------------");

  // https://github.com/wighawag/hardhat-deploy#deploymentsdeployname-options
  // const contract = await deploy("ERC721Basic", {
  //   from: deployer,
  //   args: ["Block Chain", "BC"],
  // });

  // console.log(contract.address);
};
