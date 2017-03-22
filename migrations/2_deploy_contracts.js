var EthMultiplier = artifacts.require("./EthMultiplier.sol");

module.exports = function(deployer) {
  deployer.deploy(EthMultiplier);
};
