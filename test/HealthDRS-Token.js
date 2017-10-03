
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashMock = artifacts.require('./helpers/HealthCashMock.sol');
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Token', function(accounts) {

  beforeEach(async function() {
    this.token = await HealthCashMock.new()
    this.drs = await HealthDRS.new()
    await this.drs.setHealthCashToken(this.token.address)
  })

  it('should have a valid address as token contract', async function() {
    let tokenAddress = await this.drs.token()
    let valid = isAddress(tokenAddress)
    valid.should.be.equal(true)
  })

  it('should correctly reference the token contract', async function() {
    const tokenAddress = await this.drs.token()
    tokenAddress.should.be.equal(this.token.address)  
  })

  it('should start unable to spend tokens', async function() {
    const allowance = await this.drs.authorizedToSpend()
    allowance.should.be.bignumber.equal(0)  
  })  

  it('should return the correct allowance after authorizing', async function() {
    await this.token.approve(this.drs.address, 100);
    const allowance = await this.drs.authorizedToSpend()
    allowance.should.be.bignumber.equal(100)  
  }) 

  it('should return the correct total after creating a key', async function() {
    await this.token.approve(this.drs.address, 1);
    let key = await this.drs.createKey('url-here')

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(99,'Should have spent 1 to create a key.')
  }) 

})
