var hlthDRS = artifacts.require("./HealthDRS.sol")
var transmute = artifacts.require("./TransmuteAgent.sol")

module.exports = function(deployer) {
    deployer.deploy(hlthDRS)
    deployer.deploy(transmute)    
};
