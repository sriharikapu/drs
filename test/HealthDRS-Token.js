
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Token', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-12-25').getTime()/1000
    var endDateTime = new Date('2018-1-25').getTime()/1000  
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
    const healthDRSAddress = await this.token.healthDRS()
    this.drs = HealthDRS.at(healthDRSAddress)     
    await this.drs.setRegistrationPrice(1)   
  })

  it('should start unable to spend tokens', async function() {
    const allowance = await this.drs.authorizedToSpend()
    allowance.should.be.bignumber.equal(0)  
  })  

  it('should return the correct allowance after authorizing', async function() {
    await this.token.authorizeHealthDRS(100)
    const allowance = await this.drs.authorizedToSpend()
    allowance.should.be.bignumber.equal(100)  
  }) 

  it('should return the correct total after registering a gatekeeper', async function() {
    await this.token.authorizeHealthDRS(1)
    let key = await this.drs.registerGatekeeper('url-here')

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(99,'Should have spent 1 to register a gatekeeper.')
  }) 

})
