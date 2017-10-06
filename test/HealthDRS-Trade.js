
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Trade', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('key owners should be able to trade keys', async function() {

    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    //give account 1 some tokens to spend for this test
    let tx2 = await this.drs.createKey(this.url,{from: accounts[1]})
    let key2 = tx2.logs[0].args._key

    let owner = await this.drs.getKeyOwner(key2)
    owner.should.equal(accounts[1])    

    await this.drs.tradeKey(key2, key1, {from: accounts[1]})
    await this.drs.tradeKey(key1, key2)

    owner = await this.drs.getKeyOwner(key2)
    owner.should.equal(accounts[0]) 

    owner = await this.drs.getKeyOwner(key1)
    owner.should.equal(accounts[1])
  })

  it('non-owners should not be able to trade keys', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    let tx2 = await this.drs.createKey(this.url,{from: accounts[1]})
    let key2 = tx2.logs[0].args._key

    let owner = await this.drs.getKeyOwner(key2)
    owner.should.equal(accounts[1])    

    await this.drs.tradeKey(key2, key1, {from: accounts[1]})
    //trying to trade a key we don't own
    await this.drs.tradeKey(key1, key2, {from: accounts[1]}) 

    owner = await this.drs.getKeyOwner(key2)
    owner.should.not.equal(accounts[0]) 

    owner = await this.drs.getKeyOwner(key1)
    owner.should.not.equal(accounts[1])
  })

  it('should update account keys when trading', async function() {
    let tx0 = await this.drs.createKey(this.url)
    let key0 = tx0.logs[0].args._key

    let tx1 = await this.drs.createKey(this.url,{from: accounts[1]})
    let key1 = tx1.logs[0].args._key

    await this.drs.tradeKey(key1, key0, {from: accounts[1]})
    await this.drs.tradeKey(key0, key1)

    let account0key = await this.drs.accountKeys(accounts[0],0)
    let account1key = await this.drs.accountKeys(accounts[1],0)
    
    account0key.should.be.equal(key1)
    account1key.should.be.equal(key0)
  })
  
  it('creating a trade offer should negate an active sales offer', async function() {
    let tx0 = await this.drs.createKey(this.url)
    let key0 = tx0.logs[0].args._key

    await this.drs.createSalesOffer(key0, accounts[1], 5)
    await this.drs.tradeKey(key0, key0)

    //inspect sales offer
    let so = await this.drs.salesOffers(key0)
    so[0].should.equal('0x0000000000000000000000000000000000000000')
    so[1].should.be.bignumber.equal(0)
  })

})
