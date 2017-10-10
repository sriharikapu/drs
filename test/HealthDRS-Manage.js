
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
  })
  
  it('A parent key should be its childrens ancestor', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey, childKey)
    isAncestor.should.equal(true)
  })

  it('should be able to determine ancestry correctly', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey1 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey1) 
    let childKey2 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey2) 
    let childKey3 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey3) 
    let childKey4 = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey, childKey4)
    isAncestor.should.equal(true)
  })

  it('A key should not be ancestor to a non-decendant key', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createKey(this.url)
    let rootKey2 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey2) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey1, childKey)
    isAncestor.should.equal(false)
  })

  it('A key should not be its own ancestor', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key
    let isAncestor = await this.drs.isAncestor(rootKey, rootKey)
    isAncestor.should.equal(false)
  })

  
  it('An owned ancestor key should be able to move a descendant', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createKey(this.url)
    let rootKey2 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1) 
    let childKey = tx.logs[0].args._key
    let isAncestor = await this.drs.isAncestor(rootKey2, childKey)
    isAncestor.should.equal(false)

    //move from own key you own to another you own
    await this.drs.moveKey(rootKey1, childKey, rootKey2)
    isAncestor = await this.drs.isAncestor(rootKey2, childKey)
    isAncestor.should.equal(true)
  })


  it('Should not be able to move a descendent with a key you do not own', async function() {
    let tx = await this.drs.createKey(this.url,{from: accounts[1]})
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createKey(this.url)
    let rootKey2 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1,{from: accounts[1]}) 
    let childKey = tx.logs[0].args._key
    
    //move from own key you don't own to own you own
    await this.drs.moveKey(rootKey1, childKey, rootKey2)
    let isAncestor = await this.drs.isAncestor(rootKey2, childKey)
    isAncestor.should.equal(false)
  })

  it('Should not be able to move a descendent to a key you do not own', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createKey(this.url,{from: accounts[1]})
    let rootKey2 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1) 
    let childKey = tx.logs[0].args._key
    
    //move from own key you own to own you don't own
    await this.drs.moveKey(rootKey1, childKey, rootKey2)
    let isAncestor = await this.drs.isAncestor(rootKey2, childKey)
    isAncestor.should.equal(false)
  })  

  it('An owned ancestor key should be able to access a keys data', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey1, childKey)
    isAncestor.should.equal(true)

    //set data for a descendent
    await this.drs.setKeyData(rootKey1, childKey, 'permissions', 'read')
    let permissions = await this.drs.getKeyData(rootKey1, childKey, 'permissions')
    
    //because we are using bytes32 to store thing instead of string we have to 
    //do some processing to get it back to how we sent it
    //using the string type would avoid this but would prevent 
    //this functions from being useful to other contracts
    web3.toAscii(permissions).replace(/\0/g,'').should.equal('read')
    
  })

  it('A non owned ancestor key should not be able to access a keys data', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey1, childKey)
    isAncestor.should.equal(true)

    await this.drs.setKeyData(rootKey1, childKey, 'permissions', 'read')
    let permissions = await this.drs.getKeyData(rootKey1, childKey, 'permissions', {from: accounts[1]})
    permissions.should.be.equal('0x')

  })

  it('you should be able to get ancestor count', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey1 = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey1) 
    let childKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey) 
    let grandChildKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey1, childKey)
    isAncestor.should.equal(true)

    let count = await this.drs.getAncestorCount(childKey)
    count.should.be.bignumber.equal(1)
    
    count = await this.drs.getAncestorCount(grandChildKey)
    count.should.be.bignumber.equal(2)
  })

  it('you should be able to get ancestor keys from descendant', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey) 
    let grandChildKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey, childKey)
    isAncestor.should.equal(true)

    let count = await this.drs.getAncestorCount(childKey)
    count.should.be.bignumber.equal(1)
    
    let fetchedAncestor = await this.drs.getAncestor(childKey, 0);
    fetchedAncestor.should.equal(rootKey)

    count = await this.drs.getAncestorCount(grandChildKey)
    count.should.be.bignumber.equal(2)

    fetchedAncestor = await this.drs.getAncestor(grandChildKey, 1);
    fetchedAncestor.should.equal(childKey)

    fetchedAncestor = await this.drs.getAncestor(grandChildKey, 0);
    fetchedAncestor.should.equal(rootKey)

  })

  it('should not return a non-existant ancestor key', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    let isAncestor = await this.drs.isAncestor(rootKey, childKey)
    isAncestor.should.equal(true)

    let count = await this.drs.getAncestorCount(childKey)
    count.should.be.bignumber.equal(1)
    
    let fetchedAncestor = await this.drs.getAncestor(childKey, 5);
    fetchedAncestor.should.equal('0x')

    fetchedAncestor = await this.drs.getAncestor('fakekey', 0);
    fetchedAncestor.should.equal('0x')

  })

  it('should return a key', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    let key = await this.drs.getKey(rootKey)
    key[0].should.equal(accounts[0])

  })

  it('should allow ancestors to set key permissions', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    let key = await this.drs.getKey(childKey)
    key[2].should.equal(false)

    await this.drs.setKeyPermissions(rootKey, childKey, true, true, false)
    key = await this.drs.getKey(childKey)
    key[2].should.equal(true)
    key[3].should.equal(true)    
  })

  it('ancestors should not be able to grant permissions they do not own', async function() {
    let tx = await this.drs.createKey(this.url)
    let rootKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(rootKey) 
    let childKey = tx.logs[0].args._key

    tx = await this.drs.createChildKey(childKey) 
    let grandChildKey = tx.logs[0].args._key

    let key = await this.drs.getKey(grandChildKey)
    key[2].should.equal(false)

    await this.drs.setKeyPermissions(childKey, grandChildKey, true, true, false)
    key = await this.drs.getKey(grandChildKey)
    key[2].should.equal(false)
    key[3].should.equal(false)    
    
  })

})
