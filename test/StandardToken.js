'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")

contract('HealthCash :: StandardToken', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-08-25T20:23:01.804Z').getTime()
    var endDateTime = new Date('2017-10-25T20:23:01.804Z').getTime()    
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
  })

  it('should return the correct totalSupply after construction', async function() {
    let totalSupply = await this.token.totalSupply()

    totalSupply.should.be.bignumber.equal(100)
  })

  it('should return the correct allowance amount after approval', async function() {
    await this.token.approve(accounts[1], 100)
    let allowance = await this.token.allowance(accounts[0], accounts[1])

    allowance.should.be.bignumber.equal(100)
  })

  it('should return correct balances after transfer', async function() {
    await this.token.transfer(accounts[1], 100)
    let balance0 = await this.token.balanceOf(accounts[0])
    balance0.should.be.bignumber.equal(0)

    let balance1 = await this.token.balanceOf(accounts[1])
    balance1.should.be.bignumber.equal(100)
  })

  it('should be unable to transfer more than balance', async function() {
    await this.token.transfer(accounts[1], 101)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100,'Should have failed to transfer tokens.')
  })

  it('should return correct balances after transfering from another account', async function() {
    await this.token.approve(accounts[1], 100)
    await this.token.transferFrom(accounts[0], accounts[2], 100, {from: accounts[1]})

    let balance0 = await this.token.balanceOf(accounts[0])
    balance0.should.be.bignumber.equal(0)

    let balance1 = await this.token.balanceOf(accounts[2])
    balance1.should.be.bignumber.equal(100)

    let balance2 = await this.token.balanceOf(accounts[1])
    balance2.should.be.bignumber.equal(0)
  })


  it('should not allow transfering more than allowed', async function() {
    await this.token.approve(accounts[1], 99)
    await this.token.transferFrom(accounts[0], accounts[2], 100, {from: accounts[1]})

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)

  })

})
