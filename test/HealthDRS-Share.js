
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

    let tx2 = await this.drs.createChildKey(rootKey) 
    let childKey = tx2.logs[0].args._key   

    //create shared key
    let tx3 = await this.drs.shareKey(rootKey, accounts[1])
    let sharedKey = tx3.logs[0].args._key   

    let isAncestor = await this.drs.isAncestor(sharedKey, childKey, {from: accounts[1]})
    isAncestor.should.be.true

  })

})
