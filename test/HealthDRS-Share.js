
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
  
  it('key owners should be able to share a key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let rootKey = tx1.logs[0].args._key
    
    let ownsKey = await this.drs.isOwner(rootKey, accounts[1])
    ownsKey.should.equal(false)

    //share key
    await this.drs.shareKey(rootKey, accounts[1])

    ownsKey = await this.drs.isOwner(rootKey, accounts[1])
    ownsKey.should.equal(true)

  })

  it('key owners should be able to unshare a key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let rootKey = tx1.logs[0].args._key
    
    let ownsKey = await this.drs.isOwner(rootKey, accounts[1])
    ownsKey.should.equal(false)

    //share key
    await this.drs.shareKey(rootKey, accounts[1])

    ownsKey = await this.drs.isOwner(rootKey, accounts[1])
    ownsKey.should.equal(true)

    await this.drs.unShareKey(rootKey, accounts[1])
    ownsKey = await this.drs.isOwner(rootKey, accounts[1])
    ownsKey.should.equal(false)

  })

  it('non-shareable key should not be able to share', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let rootKey = tx1.logs[0].args._key
    
    //child key is not shareable by default
    let tx2 = await this.drs.createChildKey(rootKey)
    let childKey = tx2.logs[0].args._key

    let ownsKey = await this.drs.isOwner(childKey, accounts[1])
    ownsKey.should.equal(false)

    //share key
    await this.drs.shareKey(childKey, accounts[1])

    ownsKey = await this.drs.isOwner(childKey, accounts[1])
    ownsKey.should.equal(false)

  })


})
