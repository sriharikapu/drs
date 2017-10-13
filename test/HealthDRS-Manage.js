
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashMock = artifacts.require('./helpers/HealthCashMock.sol');
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Manage', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'
    let tx = await this.drs.createService(this.url)
    this.service = tx.logs[0].args._service       
  })

  it('should be able to get a key', async function() {
    let tx = await this.drs.createKey(this.service)
    let key = tx.logs[0].args._key
    key = await this.drs.getKey(key)
    key[0].should.equal(accounts[0])
  })

  it('should be able to get a service', async function() {
    let service = await this.drs.getService(this.service)
    service[0].should.equal(this.url)
    service[1].should.equal(accounts[0])
  })

  it('should allow service owner to set key permissions', async function() {
    let tx = await this.drs.createKey(this.service)
    let key1 = tx.logs[0].args._key
    let key = await this.drs.getKey(key1)
    key[2].should.equal(false)

    await this.drs.setKeyPermissions(key1, true, true, false)
    key = await this.drs.getKey(key1)
    key[1].should.equal(true)
    key[2].should.equal(true)    
  })

  it('should be able to get service count', async function() {
    let count = await this.drs.getServiceCount()
    count.should.be.bignumber.equal(1)
  })

  it('should be able to get a service key from the service list', async function() {
    let service1 = await this.drs.serviceList(0)
    service1.should.be.equal(this.service)
  })

  it('should be able to get key count', async function() {
    await this.drs.createKey(this.service)
    await this.drs.createKey(this.service)
    let count = await this.drs.getKeyCount()
    count.should.be.bignumber.equal(2)
  })

  it('should be able to get a key from the key list', async function() {
    let tx = await this.drs.createKey(this.service)
    let key = tx.logs[0].args._key    
    let retrievedKey = await this.drs.keyList(0)
    retrievedKey.should.be.equal(key)
  })

})
