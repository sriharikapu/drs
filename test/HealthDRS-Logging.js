
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")

contract('HealthDRS :: Logging', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('should enable a key owner to log', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.log(rootKey, 'test log')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(rootKey);        
    tx.logs[0].args._data.should.equal('test log');
  })

  it('should not enable a non-owner to log', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.log(rootKey, 'test log',{from: accounts[1]})
    tx.logs.length.should.equal(0)
  }) 

  it('should enable an ancestor owner to log access', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey, childKey)
    isAncestor.should.equal(true)

    tx = await this.drs.logAccess(rootKey, childKey, 'datastring')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(rootKey);        
    tx.logs[0].args._to.should.equal(childKey);    
    tx.logs[0].args._data.should.equal('datastring');
  })

  it('should enable a key owner to message', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    tx = await this.drs.message(rootKey, childKey, 'init', 'data')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(rootKey);        
    tx.logs[0].args._to.should.equal(childKey);
    tx.logs[0].args._category.should.equal('init');        
    tx.logs[0].args._data.should.equal('data');
    
    tx = await this.drs.message(childKey, rootKey, 'init', 'data')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(childKey);        
    tx.logs[0].args._to.should.equal(rootKey);
    tx.logs[0].args._category.should.equal('init');        
    tx.logs[0].args._data.should.equal('data');

  })

  it('should not enable a non-owner to message', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    tx = await this.drs.message(rootKey, childKey, 'init', 'data', {from: accounts[1]})
    tx.logs.length.should.equal(0)
  })


})
