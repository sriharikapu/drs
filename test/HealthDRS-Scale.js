
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Scalability', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('should be able to create large key sets', async function() {

    let tx = await this.drs.createKey(this.url)
    let key = tx.logs[0].args._key
    let firstkey = key 

    for (var i = 0; i < 100; i++) {
        tx = await this.drs.createChildKey(key)
        key = tx.logs[0].args._key
    }

    let ancestorCount = await this.drs.getAncestorCount(key)
    ancestorCount.should.be.bignumber.equal(100)
    
    let isAncestor = await this.drs.isAncestor(firstkey, key)
    isAncestor.should.equal(true)

  })

})
