'use strict';
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashMock = artifacts.require('./helpers/HealthCashMock.sol')
var TransmuteAgent = artifacts.require("./TransmuteAgent.sol")

contract('TransmuteAgent', function(accounts) {

  beforeEach(async function() {
    this.token = await HealthCashMock.new()
    this.agent = await TransmuteAgent.new()
    await this.agent.setTokenToTransmute(this.token.address)
  })

  it('should not allow transmutation until enabled', async function() {
    let validAddress = accounts[1]
    await this.agent.transmuteToken(validAddress, 10)
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(100)
  })

  it('should return the correct token total after tranmuting some', async function() {
    
    //Tranmutation Agent must be explictly approved
    await this.token.approve(this.agent.address, 10);    
    await this.agent.enable(true) 

    let validAddress = accounts[0]
    await this.agent.transmuteToken(validAddress, 10)

    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(90)
  })

  it('should return the correct balance after transmuting some', async function() {

    //Tranmutation Agent must be explictly approved
    await this.token.approve(this.agent.address, 10);
    await this.agent.enable(true)    

    let validAddress = accounts[0]
    await this.agent.transmuteToken(validAddress,10)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(90)
  })

  it('should be unable to transmute too many tokens', async function() {
    //Tranmutation Agent must be explictly approved
    await this.token.approve(this.agent.address, 100);
    await this.agent.enable(true)    
    await this.agent.transmuteToken(accounts[0],900)
    
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100)
    
    let totalSupply = await this.token.totalSupply()    
    totalSupply.should.be.bignumber.equal(100)    
  })

  it('should be unable to transmute from an account without authorization', async function() {
    await this.agent.enable(true)    
    await this.agent.transmuteToken(accounts[0],100)
    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100,'was able to transfer unauthorized tokens')
  })


  it('should increment the Trasmute Agent Nonce', async function() {
    
    await this.token.approve(this.agent.address, 2);        
    await this.agent.enable(true)  
    let validAddress = accounts[1]

    await this.agent.transmuteToken(validAddress,1)
    let transmuteNonce = await this.agent.transmuteNonce()    
    transmuteNonce.should.be.bignumber.equal(1)

    await this.agent.transmuteToken(validAddress,1)
    transmuteNonce = await this.agent.transmuteNonce()    
    transmuteNonce.should.be.bignumber.equal(2)
  })


  it('should create a valid Transmute Event', async function() {
    await this.token.approve(this.agent.address, 10);        
    await this.agent.enable(true)  
    let validAddress = accounts[1]
    let tx = await this.agent.transmuteToken(validAddress, 10)

    let event = tx.logs[0].event
    event.should.be.equal('Transmute')

    let from = tx.logs[0].args._from
    from.should.equal(accounts[0])

    let to = tx.logs[0].args._to
    to.should.equal(validAddress)

    let total = tx.logs[0].args._value
    total.should.be.bignumber.equal(10)

    let id = tx.logs[0].args._id
    id.should.not.be.empty

  })


})
