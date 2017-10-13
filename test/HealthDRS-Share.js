
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Share', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('service owners should be able to share a service', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    let ownsService = await this.drs.isServiceOwner(service, accounts[1])
    ownsService.should.equal(false)
    await this.drs.shareService(service, accounts[1])
    ownsService = await this.drs.isServiceOwner(service, accounts[1])
    ownsService.should.equal(true)
  })

  it('service owners should be able to unshare a service', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    let ownsService = await this.drs.isServiceOwner(service, accounts[1])
    ownsService.should.equal(false)
    await this.drs.shareService(service, accounts[1])
    ownsService = await this.drs.isServiceOwner(service, accounts[1])
    ownsService.should.equal(true)
    await this.drs.unshareService(service, accounts[1])
    ownsService = await this.drs.isServiceOwner(service, accounts[1])
    ownsService.should.equal(false)
  })

  it('key owners should be able to unshare a key', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service

    let tx1 = await this.drs.createKey(service)
    let rootKey = tx1.logs[0].args._key

    //give share permissions
    await this.drs.setKeyPermissions(rootKey, true, false, false);
    let ownsKey = await this.drs.isKeyOwner(rootKey, accounts[1])
    ownsKey.should.equal(false)

    //share key
    await this.drs.shareKey(rootKey, accounts[1])

    ownsKey = await this.drs.isKeyOwner(rootKey, accounts[1])
    ownsKey.should.equal(true)

    await this.drs.unshareKey(rootKey, accounts[1])
    ownsKey = await this.drs.isKeyOwner(rootKey, accounts[1])
    ownsKey.should.equal(false)
  })

  it('non-shareable key should not be able to share', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    
    //key is not shareable by default
    let tx2 = await this.drs.createKey(service)
    let childKey = tx2.logs[0].args._key

    let ownsKey = await this.drs.isKeyOwner(childKey, accounts[1])
    ownsKey.should.equal(false)

    //share key
    await this.drs.shareKey(childKey, accounts[1])

    ownsKey = await this.drs.isKeyOwner(childKey, accounts[1])
    ownsKey.should.equal(false)
  })


})
