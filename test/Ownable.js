const BigNumber = web3.BigNumber
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

var HealthDRS = artifacts.require("./HealthDRS.sol")

contract('HealthDRS :: Ownable', function(accounts) {

  beforeEach(async function() {
    this.ownable = await HealthDRS.new()
  })

  it('should have an owner', async function() {
    let owner = await this.ownable.owner()
    owner.should.not.be.equal(0)    
  })

  it('changes owner after transfer', async function() {
    let other = accounts[1]
    await this.ownable.transferOwnership(other)
    let owner = await this.ownable.owner();

    owner.should.be.equal(other)    
  })

  it('should prevent non-owners from transfering', async function() {
    const other = accounts[2]
    let owner = await this.ownable.owner.call()
    owner.should.not.be.equal(other)    

    await this.ownable.transferOwnership(other, {from: other})
    owner = await this.ownable.owner.call()

    owner.should.not.be.equal(other)
  })

  it('should guard ownership against stuck state', async function() {
    let originalOwner = await this.ownable.owner()
    await this.ownable.transferOwnership(null, {from: originalOwner})
    let newOwner = await this.ownable.owner()

    newOwner.should.be.equal(originalOwner)
  })

})
