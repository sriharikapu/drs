
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
    let tx = await this.drs.createService(this.url)
    this.service = tx.logs[0].args._service       
  })
  
  it('should enable a key owner to log', async function() {
    let tx = await this.drs.createKey(this.service)
    let key = tx.logs[0].args._key

    tx = await this.drs.log(key, 'test log')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(key);        
    tx.logs[0].args._data.should.equal('test log');
  })

  it('should not enable a non-owner to log', async function() {
    let tx = await this.drs.createKey(this.service)
    let rootKey = tx.logs[0].args._key
    tx = await this.drs.log(rootKey, 'test log',{from: accounts[1]})
    tx.logs.length.should.equal(0)
  }) 

  it('should enable a service owner to log access', async function() {
    
    let tx = await this.drs.createKey(this.service)
    let key = tx.logs[0].args._key

    tx = await this.drs.logAccess(this.service, key, 'datastring')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(this.service);        
    tx.logs[0].args._to.should.equal(key);    
    tx.logs[0].args._data.should.equal('datastring');
  })

  it('should enable a key owner to message', async function() {
    let tx = await this.drs.createKey(this.service)
    let key1 = tx.logs[0].args._key

    tx = await this.drs.createKey(this.service) 
    let key2 = tx.logs[0].args._key

    tx = await this.drs.message(key1, key2, 'init', 'data')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(key1);        
    tx.logs[0].args._to.should.equal(key2);
    tx.logs[0].args._category.should.equal('init');        
    tx.logs[0].args._data.should.equal('data');
    
    tx = await this.drs.message(key2, key1, 'init', 'data')
    tx.logs[0].args._owner.should.equal(accounts[0]);    
    tx.logs[0].args._from.should.equal(key2);        
    tx.logs[0].args._to.should.equal(key1);
    tx.logs[0].args._category.should.equal('init');        
    tx.logs[0].args._data.should.equal('data');

  })

  it('should not enable a non-owner to message', async function() {
    let tx = await this.drs.createKey(this.service)
    let key1 = tx.logs[0].args._key
    tx = await this.drs.createKey(this.service) 
    let key2 = tx.logs[0].args._key
    tx = await this.drs.message(key1, key2, 'init', 'data', {from: accounts[1]})
    tx.logs.length.should.equal(0)
  })


})
