'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")

contract('HealthCash :: SaleTransferLock', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-08-25').getTime()/1000
    var endDateTime = new Date('2017-10-25').getTime()/1000
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
  })

  it('should not allow transfering during token sale', async function() {
    await this.token.transfer(accounts[1], 100)
    await this.token.transfer(accounts[0], 100, {from: accounts[1]})
    
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(0)
  })

})
