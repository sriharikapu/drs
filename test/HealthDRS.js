
const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")
import isAddress from './helpers/isAddress'

contract('HealthDRS', function(accounts) {

  beforeEach(async function() {
    this.drs = await HealthDRS.new()
    this.url = 'https://blogs.scientificamerican.com/observations/consciousness-goes-deeper-than-you-think/'    
  })
  
  it('should be able to create a service', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    let owner = await this.drs.isServiceOwner(service, accounts[0])
    owner.should.equal(true);    
  })
 
  it('should return the correct URL when passed a service key', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    let url = await this.drs.getUrl(service) 
    url.should.equal(this.url)
  })

  it('should return the correct URL, when url is very long', async function() {
    let longurl = 'http://www.longurlmaker.com/go?id=6bSitelutionsf4URL.co.ukLiteURLr1Shorl0ShortURLfar%2Boff5rk10rangylengthy2URL.co.uk50aFhURL0uShredURL1URLHawkh816Is.gd1f8drawn%2Bout98Sitelutions011far%2Breachingremote0enduringoutstretchedfcontinued0olengthened193URLviSmallr2faraway0NanoRef6807qarexpandedtuTraceURL1sRedirx150lengthy6URLremoteaFhURL0ag301URLgreatfCanURL0TinyURLdrawn%2Bout0outstretched7lengthenedTinyURLspun%2Bout0clnk.in25b5ovextensiveIs.gdyjremoteeenlarged16Minilien0Doiop22stringy0elongate0farawaytr0glengthenedx00CanURLlongish12NotLong317XiluganglingdX.se821i1remotee830wNanoRefMyURL09llastingFwdURL35URl.ieShoterLinkXil07expanded91TinyLink5far%2Breaching0ShortURLdenlarged90000fMetamark6farawayzzdistanttalln0elengthy1lasting07qelongatedcbhfarawaye6NotLonggreat9URL.co.uk174Shrtndlengthened119k31f43FwdURLlastings6d0SmallrsxURLCutter111SnipURLrangyspun%2BoutShortenURL2loftydrawn%2Boutq97l7lengthened6c9EasyURL0WapURLenduringoutstretchedWapURL805b5jfc2stretchrunning00ganglingFhURLMooURL11enduring8NutshellURL09a8tallMyURLtURl.ieSHurl11G8L9RubyURLURL.co.uklingeringspread%2Bouto40olofty1ShortenURLspun%2Bout2acNanoRefSimURL1cYATUCG8Lfar%2BreachingrrangyWapURL518URLvi0a1elongatestringyhighgNe1tall0011CanURLe115expanded8MyURL1021YATUCNanoRef07e1w1alengthy00YepIta0h0s081fSimURL6aTinyLink0Ne123301URL011running0c020111wfarawayNe1spun%2BoutEzURL4i5outstretchedTinyLink0MooURLseYATUC091sURLPie2e1enlargedb011pexpandedgreathighMinilien4rangy0ftowering111e83yrunninglofty417e4057cNutshellURL07URl.ie9m607lasting40remote176jy745URl.ielengthy81remote8spun%2Bout0prolonged30x88longishcvSimURL02elongate527d52m47dbdvfgnStartURL1pNutshellURLo5111gangling0316drawn%2BoutRedirx3147d81farawaydrawn%2Boutd1pdRedirxdistantURLHawkf61119102516stringy1enlarged00B65lengthyg0lofty53019URLcutMinilien4Smallrn761zTraceURL7j10distantIs.gddistant7l2running101796141zhighbwTightURL1105ShortenURLrangygfar%2Boff11great1Smallrstringy1G8Llengthy0061411c1longish0URLHawk01MooURL8remote000e13jspun%2Boutbsustained0p1extensivel11TraceURLlanky19stretching05m66x810005URLHawk63continuedc20ShortenURLrangymShortURL0u1112Redirxenduring9loftylen'
    let tx = await this.drs.createService(longurl)
    let service = tx.logs[0].args._service
    let url = await this.drs.getUrl(service) 
    url.should.equal(longurl)
  })

  it('should be able to create a key', async function() {
    let tx1 = await this.drs.createService(this.url)
    let service = tx1.logs[0].args._service
    let tx2 = await this.drs.createKey(service) 
    tx2.logs[0].event.should.equal('KeyCreated')
    let key2 = tx2.logs[0].args._key    
    let owner = await this.drs.isKeyOwner(key2,accounts[0])
    owner.should.equal(true);    
  })

  it('should be able to issue a key to another account', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    tx = await this.drs.issueKey(service, accounts[1]) 
    tx.logs[0].event.should.equal('KeyCreated')
    let key = tx.logs[0].args._key    
    let owner = await this.drs.isKeyOwner(key,accounts[1])
    owner.should.equal(true);    
  })

  it('should return the correct URL when passed a key', async function() {
    let tx1 = await this.drs.createService(this.url)
    let service = tx1.logs[0].args._service
    let tx2 = await this.drs.createKey(service) 
    let key2 = tx2.logs[0].args._key  

    let url = await this.drs.getUrlFromKey(key2) 
    url.should.equal(this.url)    
  })

  it('should update url when using a service key', async function() {
    let tx = await this.drs.createService(this.url)
    let service = tx.logs[0].args._service
    
    let tx2 = await this.drs.createKey(service) 
    let key2 = tx2.logs[0].args._key  

    await this.drs.updateUrl(service,'changedUrl')    

    let url = await this.drs.getUrlFromKey(key2) 
    url.should.equal('changedUrl')    
  })


})
