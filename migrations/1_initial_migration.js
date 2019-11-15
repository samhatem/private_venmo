const Zdai = artifacts.require("./Zdai.sol");

module.exports = function(deployer) {
  deployer.deploy(Zdai);
};
