'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")

contract('HealthCash :: Health Nexus Transferable', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-08-25T20:23:01.804Z').getTime()
    var endDateTime = new Date('2017-10-25T20:23:01.804Z').getTime()    
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
  })

  it('should not allow transfers to Health Nexus until enabled', async function() {
    let validAddress = accounts[1]
    await this.token.transferToHealthNexus(validAddress,10)
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(100)
  })

  it('should return the correct token total after tranfering some to Health Nexus', async function() {
    await this.token.enableHealthNexusTransfers(true)    
    let validAddress = accounts[1]
    await this.token.transferToHealthNexus(validAddress,10)
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(90)
  })

  it('should return the correct balance after tranfering some to Health Nexus', async function() {
    await this.token.enableHealthNexusTransfers(true)        
    let validAddress = accounts[1]
    await this.token.transferToHealthNexus(validAddress,10)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(90)
  })

  it('should be unable to transfer too many tokens', async function() {
    await this.token.enableHealthNexusTransfers(true)        
    let validAddress = accounts[1]
    await this.token.transferToHealthNexus(validAddress,900)
    
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)
    
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(100)    
  })

  it('should return the correct balance after transfering from', async function() {
    await this.token.enableHealthNexusTransfers(true)        
    await this.token.transfer(accounts[1], 100)
    await this.token.approve(accounts[0], 10, {from: accounts[1]})
    let validAddress = accounts[1]
    await this.token.transferToHealthNexusFrom(accounts[1],validAddress,10)
    let balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(90)
  })

  it('should be unable to transfer from an account without authorization', async function() {
    await this.token.enableHealthNexusTransfers(true)        
    await this.token.transfer(accounts[1], 100)
    let validAddress = accounts[1]
    await this.token.transferToHealthNexusFrom(accounts[1],validAddress,10)
    let balance = await this.token.balanceOf(accounts[1])
    balance.should.be.bignumber.equal(100,'was able to transfer unauthorized tokens')
  })

  it('should increment the Health Nexus Tranfer Nonce', async function() {
    await this.token.enableHealthNexusTransfers(true)        
    let validAddress = accounts[1]
    await this.token.transferToHealthNexus(validAddress,10)
    
    let hntNonce = await this.token.hntNonce()    
    hntNonce.should.be.bignumber.equal(1)

    await this.token.transferToHealthNexus(validAddress,10)

    hntNonce = await this.token.hntNonce()    
    hntNonce.should.be.bignumber.equal(2)
  })

  it('should create a valid Health Nexus Tranfer Event', async function() {
    await this.token.enableHealthNexusTransfers(true)    
    let validAddress = accounts[1]
    let tx = await this.token.transferToHealthNexus(validAddress,10)

    let event = tx.logs[2].event
    event.should.be.equal('TransferToHealthNexus')

    let from = tx.logs[2].args._from
    from.should.equal(accounts[0])

    let to = tx.logs[2].args._to
    to.should.equal(validAddress)

    let total = tx.logs[2].args._value
    total.should.be.bignumber.equal(10)

    let id = tx.logs[2].args._transferID
    id.should.not.be.empty

  })


})
