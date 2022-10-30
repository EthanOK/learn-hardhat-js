const networkConfig = {
  5: {
    name: "goerli",
    ethUsdPriceFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
  },
  97: {
    name: "tbsc",
    ethUsdPriceFeed: "0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7",
  },
  80001: {
    name: "mumbai",
    ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
  },
  // 31337
};
const developmentChain = ["hardhat", "localhost"];

const Decimals = 8;
const InitialAnswer = 200000000000;
module.exports = {
  networkConfig,
  developmentChain,
  Decimals,
  InitialAnswer,
};
