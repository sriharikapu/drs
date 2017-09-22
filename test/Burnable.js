'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")

contract('HealthCash :: Burnable', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-08-25T20:23:01.804Z').getTime()
    var endDateTime = new Date('2017-10-25T20:23:01.804Z').getTime()    
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
  })

  it('should return the correct token total after burning', async function() {
    await this.token.burn(10)
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(90)
  })

  it('should return the correct balance after burning', async function() {
    await this.token.burn(10)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(90)
  })

  it('should return the correct balance after burning from', async function() {
    await this.token.transfer(accounts[1], 100)
    await this.token.approve(accounts[0], 10, {from: accounts[1]})
    await this.token.burnFrom(accounts[1],10);
    let balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(90)
  })

  it('should be unable to burn too many tokens', async function() {
    await this.token.burn(900)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)
  })

  it('should be unable to burn from an account without authorization', async function() {
    await this.token.transfer(accounts[1], 100)
    await this.token.burnFrom(accounts[1],10);
    let balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(100,'was able to burn unauthorized tokens')
  })

})
