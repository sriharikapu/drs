
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCash = artifacts.require("./HealthCash.sol")
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthCash :: HealthDRS', function(accounts) {

  beforeEach(async function() {
    var startDateTime = new Date('2017-08-25T20:23:01.804Z').getTime()
    var endDateTime = new Date('2017-10-25T20:23:01.804Z').getTime()    
    this.token = await HealthCash.new(100, startDateTime, endDateTime, accounts[0])
  })

  it('should deploy HealthDRS along with token', async function() {
    let healthDRS = await this.token.healthDRS()
    let valid = isAddress(healthDRS)
    valid.should.be.equal(true)
  })

  it('should correctly reference the token contract', async function() {
    const healthDRSAddress = await this.token.healthDRS()
    const healthDRS = HealthDRS.at(healthDRSAddress)    
    const tokenAddress = await healthDRS.token()
    tokenAddress.should.be.equal(this.token.address)  
  })

  it('should be updateable by admin', async function() {
    let firstDRSAddress = await this.token.healthDRS()
    await this.token.updateHealthDRS(accounts[1],'');
    let secondDRSAddress = await this.token.healthDRS()    

    secondDRSAddress.should.not.be.equal(firstDRSAddress)  
    secondDRSAddress.should.be.equal(accounts[1])  
  })

  it('should only be updateable by admin', async function() {
    let firstDRSAddress = await this.token.healthDRS()
    await this.token.updateHealthDRS(accounts[1],'',{from: accounts[1]});
    let secondDRSAddress = await this.token.healthDRS()    

    secondDRSAddress.should.be.equal(firstDRSAddress)  
    secondDRSAddress.should.not.be.equal(accounts[1])  
  })

})
