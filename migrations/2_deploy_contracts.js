var hlth = artifacts.require("./HealthCash.sol")

module.exports = function(deployer) {

    let adminAddress = '0x00a329c0648769a73afac7f9381e08fb43dbea72'
    let startDateTime = new Date('2017-08-25T20:23:01.804Z').getTime()
    let endDateTime = new Date('2017-10-25T20:23:01.804Z').getTime()   
    let tokenTotal = 100000000000000000000
    deployer.deploy(hlth, tokenTotal, startDateTime, endDateTime, adminAddress)
};
