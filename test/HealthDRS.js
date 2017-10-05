
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthCashMock = artifacts.require('./helpers/HealthCashMock.sol');
var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS', function(accounts) {

  beforeEach(async function() {
    this.token = await HealthCashMock.new()
    this.drs = await HealthDRS.new()
    await this.drs.setHealthCashToken(this.token.address)
    await this.token.approve(this.drs.address, 1)    
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('should be able to create a key', async function() {
    let tx = await this.drs.createKey('string')
    let key = tx.logs[0].args._key
    let owner = await this.drs.getKeyOwner(key)
    owner.should.equal(accounts[0]);    
  })
 
  it('should return the correct URL when passed a root key', async function() {
    let tx = await this.drs.createKey(this.url)
    let key = tx.logs[0].args._key
    let url = await this.drs.getURL(key) 
    url.should.equal(this.url)
  })

  it('should return the correct URL, when url is very long', async function() {
    let longurl = 'http://www.longurlmaker.com/go?id=6bSitelutionsf4URL.co.ukLiteURLr1Shorl0ShortURLfar%2Boff5rk10rangylengthy2URL.co.uk50aFhURL0uShredURL1URLHawkh816Is.gd1f8drawn%2Bout98Sitelutions011far%2Breachingremote0enduringoutstretchedfcontinued0olengthened193URLviSmallr2faraway0NanoRef6807qarexpandedtuTraceURL1sRedirx150lengthy6URLremoteaFhURL0ag301URLgreatfCanURL0TinyURLdrawn%2Bout0outstretched7lengthenedTinyURLspun%2Bout0clnk.in25b5ovextensiveIs.gdyjremoteeenlarged16Minilien0Doiop22stringy0elongate0farawaytr0glengthenedx00CanURLlongish12NotLong317XiluganglingdX.se821i1remotee830wNanoRefMyURL09llastingFwdURL35URl.ieShoterLinkXil07expanded91TinyLink5far%2Breaching0ShortURLdenlarged90000fMetamark6farawayzzdistanttalln0elengthy1lasting07qelongatedcbhfarawaye6NotLonggreat9URL.co.uk174Shrtndlengthened119k31f43FwdURLlastings6d0SmallrsxURLCutter111SnipURLrangyspun%2BoutShortenURL2loftydrawn%2Boutq97l7lengthened6c9EasyURL0WapURLenduringoutstretchedWapURL805b5jfc2stretchrunning00ganglingFhURLMooURL11enduring8NutshellURL09a8tallMyURLtURl.ieSHurl11G8L9RubyURLURL.co.uklingeringspread%2Bouto40olofty1ShortenURLspun%2Bout2acNanoRefSimURL1cYATUCG8Lfar%2BreachingrrangyWapURL518URLvi0a1elongatestringyhighgNe1tall0011CanURLe115expanded8MyURL1021YATUCNanoRef07e1w1alengthy00YepIta0h0s081fSimURL6aTinyLink0Ne123301URL011running0c020111wfarawayNe1spun%2BoutEzURL4i5outstretchedTinyLink0MooURLseYATUC091sURLPie2e1enlargedb011pexpandedgreathighMinilien4rangy0ftowering111e83yrunninglofty417e4057cNutshellURL07URl.ie9m607lasting40remote176jy745URl.ielengthy81remote8spun%2Bout0prolonged30x88longishcvSimURL02elongate527d52m47dbdvfgnStartURL1pNutshellURLo5111gangling0316drawn%2BoutRedirx3147d81farawaydrawn%2Boutd1pdRedirxdistantURLHawkf61119102516stringy1enlarged00B65lengthyg0lofty53019URLcutMinilien4Smallrn761zTraceURL7j10distantIs.gddistant7l2running101796141zhighbwTightURL1105ShortenURLrangygfar%2Boff11great1Smallrstringy1G8Llengthy0061411c1longish0URLHawk01MooURL8remote000e13jspun%2Boutbsustained0p1extensivel11TraceURLlanky19stretching05m66x810005URLHawk63continuedc20ShortenURLrangymShortURL0u1112Redirxenduring9loftylen'
    let tx = await this.drs.createKey(longurl)
    let key = tx.logs[0].args._key
    let url = await this.drs.getURL(key) 
    url.should.equal(longurl)
  })

  it('should be able to create a child key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    let tx2 = await this.drs.createChildKey(key1) 
    tx2.logs[0].event.should.equal('KeyCreated')
    let key2 = tx2.logs[0].args._key    
    
    let owner = await this.drs.getKeyOwner(key2)
    owner.should.equal(accounts[0]);    
  })

  it('should return the correct URL when passed a child key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    let tx2 = await this.drs.createChildKey(key1) 
    let key2 = tx2.logs[0].args._key  

    let url = await this.drs.getURL(key2) 
    url.should.equal(this.url)    
  })

  it('should be able to create a peer key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    let tx2 = await this.drs.createPeerKey(key1) 
    tx2.logs[0].event.should.equal('KeyCreated')
    let key2 = tx2.logs[0].args._key    
    
    let owner = await this.drs.getKeyOwner(key2)
    owner.should.equal(accounts[0]);    
  })

  it('should return the correct URL when passed a peer key', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    let tx2 = await this.drs.createPeerKey(key1) 
    let key2 = tx2.logs[0].args._key  

    let url = await this.drs.getURL(key2) 
    url.should.equal(this.url)    
  })

  it('should update url when using a root key', async function() {
    let tx = await this.drs.createKey(this.url)
    let key = tx.logs[0].args._key
    
    let tx2 = await this.drs.createChildKey(key) 
    let key2 = tx2.logs[0].args._key  

    await this.drs.updateURL(key,'changedUrl')    

    let url = await this.drs.getURL(key2) 
    url.should.equal('changedUrl')    
  })
 
  it('should be able to clone a key you own', async function() {
    let tx1 = await this.drs.createKey(this.url)
    let key1 = tx1.logs[0].args._key
    
    let tx2 = await this.drs.createChildKey(key1) 
    let key2 = tx2.logs[0].args._key  
    
    let tx3 = await this.drs.createCloneKey(key1)
    let key3 = tx3.logs[0].args._key

    //changing the url with the cloned key should 
    //effect all the child keys of the original keys
    await this.drs.updateURL(key3,'changedUrl')
        
    let url = await this.drs.getURL(key2) 
    url.should.equal('changedUrl')        

  })

})
