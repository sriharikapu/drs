
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashMock = artifacts.require('./helpers/HealthCashMock.sol');
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS :: Sell', function(accounts) {

  beforeEach(async function() {
    this.token = await HealthCashMock.new()
    this.drs = await HealthDRS.new()
    await this.drs.setHealthCashToken(this.token.address)
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('key owner should be able to put a key up for sale only if salable', async function() {
    //root keys default to salable
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    await this.drs.createSalesOffer(key1, accounts[1], 5)
    let so = await this.drs.salesOffers(key1)
    so[0].should.equal(accounts[1],'buyer was not correct address')
    so[1].should.be.bignumber.equal(5,'price was not set correctly')

    //child keys default to non-salable
    let tx2 = await this.drs.createChildKey(key1)
    let childKey = tx2.logs[0].args._key

    //should fail - having no permissions to sell
    await this.drs.createSalesOffer(childKey, accounts[1], 5)
    so = await this.drs.salesOffers(childKey)
    so[0].should.not.equal(accounts[1])
    so[1].should.not.be.bignumber.equal(5)

    //give key permission to sell - should suceed
    await this.drs.setKeyPermissions(key1, childKey, false, false, true)
    await this.drs.createSalesOffer(childKey, accounts[1], 5)
    so = await this.drs.salesOffers(childKey)
    so[0].should.equal(accounts[1])
    so[1].should.be.bignumber.equal(5)

  })
  
  it('putting a key up for sale should negate an active trade offer', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    let tx2 = await this.drs.createKey(this.url,{from: accounts[1]})
    let key2 = tx2.logs[0].args._key

    await this.drs.tradeKey(key1, key2)    
    await this.drs.createSalesOffer(key1, accounts[1], 5)

    let to = await this.drs.tradeOffers(key1)
    to.should.equal('0x0000000000000000000000000000000000000000000000000000000000000000')
  })
 
  it('non owner should not be able to list a key for sale', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    //try to create a sales offer from the account that wants to buy a key
    await this.drs.createSalesOffer(key1, accounts[1], 5, {from: accounts[1]})
    let so = await this.drs.salesOffers(key1)
    so[0].should.not.equal(accounts[1])
    so[1].should.not.be.bignumber.equal(5)
   })

   it('should not be able to purchase an unoffered key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key

    this.token.transfer(accounts[1],1)
    await this.token.approve(this.drs.address, 1, {from: accounts[1]})  
    await this.drs.purchaseKey(key1, 1, {from: accounts[1]})
    let owner = await this.drs.isOwner(key1,accounts[0])
    owner.should.equal(true)  
   })

   it('should be able to purchase an offered key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    await this.drs.createSalesOffer(key1, accounts[1], 5)

    //give account some HLTH to spend 
    this.token.transfer(accounts[1],5)
    await this.token.approve(this.drs.address, 5, {from: accounts[1]})  
    await this.drs.purchaseKey(key1, 5, {from: accounts[1]})

    let owner = await this.drs.isOwner(key1,accounts[1])
    owner.should.equal(true)  

    let balance = await this.token.balanceOf(accounts[0])
    balance.should.be.bignumber.equal(100,'Should have gotten 5 tokens back')
   })

   it('a key owner should be able to cancel a sales offer', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    await this.drs.createSalesOffer(key1, accounts[1], 5)
    await this.drs.cancelSalesOffer(key1)
    let so = await this.drs.salesOffers(key1)
    so[0].should.equal('0x0000000000000000000000000000000000000000')
   })
   

   it('a key owner should be able to update the price on a sales offer', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    await this.drs.createSalesOffer(key1, accounts[1], 5)

    //overwrite old with new
    await this.drs.createSalesOffer(key1, accounts[1], 50)        
    let so = await this.drs.salesOffers(key1)
    so[1].should.be.bignumber.equal(50)
   })

})
