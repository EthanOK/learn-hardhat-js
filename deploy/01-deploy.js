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
};
