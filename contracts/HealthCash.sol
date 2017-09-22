pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './HealthDRS.sol';

contract HealthCash is StandardToken, Ownable {

    string  public  constant name = "Health Cash";
    string  public  constant symbol = "HLTH";
    uint    public  constant decimals = 18;
    uint    public  saleStarts;
    uint    public  saleEnds;
    address public  saleContract;

    /* 
    * The Health Cash token (HLTH) is deployed alongside a 
    * decentralized record service (HealthDRS) where HLTH
    * can be used to manage ownership and access to offchain
    * records.
    *
    * The latest DRS contract will always be refrenced here
    * in the token contract. If/when an interface becomes
    * available it will also be referenced here. 
    */
    address public healthDRS; 
    bytes   public healthDRSurl;     

    /*
    * The Health Cash token (HLTH) will be voluntarily 
    * transferable to the Health Nexus blockchain once 
    * Health Nexus is deployed for public use.
    */
    bool public healthNexusTransfersEnabled = false;
    uint public hntNonce = 0; 

    modifier onlyWhenTransferable() {
        if (now >= saleStarts && now <= saleEnds) {
            require(msg.sender == saleContract);
        }
        _;
    }

    modifier validTo( address to ) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

   /**
   * Prevent short address attack
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
    modifier withPayloadSize(uint size) {
         assert(msg.data.length == size + 4);
        _;
    }

    function HealthCash( uint tokenTotalAmount, uint startTime, uint endTime, address admin) {
        
        // Mint tokens at the start, then disable minting.
        balances[msg.sender] = tokenTotalAmount;
        totalSupply = tokenTotalAmount;
        Transfer(address(0x0), msg.sender, tokenTotalAmount);

        saleStarts = startTime;
        saleEnds = endTime;

        saleContract = msg.sender;
        transferOwnership(admin); 

        //Deploy initial DRS. The DRS contract is updateable 
        healthDRS = address(new HealthDRS(this, admin));
    }

    /**
    * HLTH can not be transfered until after the sale
    * */
    function transfer(address _to, uint _value)
    withPayloadSize(2 * 32)
    onlyWhenTransferable
    validTo(_to)
    returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
    onlyWhenTransferable
    validTo(_to)
    returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * HLTH is Burnable
    * Unsold HLTH will be burned after the token sale completes. 
    * HLTH transfered to Health Nexus will also be burned. 
    * */
    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) 
    onlyWhenTransferable
    returns (bool) 
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) 
    onlyWhenTransferable
    returns (bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

   /**
    * HLTH is cross-chain Transferable
    * Transfering HLTH to Health Nexus burns
    * the HLTH tokens. 
    */
    event TransferToHealthNexus(address indexed _from, address indexed _to, uint _value, bytes32 _transferID);

    function transferToHealthNexus(address _to, uint _value) returns (bool) {
        require(healthNexusTransfersEnabled);
        assert(burn(_value));
        hntNonce += 1;
        bytes32 transferID = keccak256(now,hntNonce,_to);
        TransferToHealthNexus(msg.sender, _to, _value, transferID);
        return true;
    }

    function transferToHealthNexusFrom(address _from, address _to, uint _value) returns (bool) {
        require(healthNexusTransfersEnabled);        
        assert(transferFrom(_from, msg.sender, _value));
        assert(burn(_value));
        hntNonce += 1;
        bytes32 transferID = keccak256(now,hntNonce,_to);
        TransferToHealthNexus(msg.sender, _to, _value, transferID);
        return true;
    }

    function enableHealthNexusTransfers(bool enabled) 
    onlyOwner 
    {
        healthNexusTransfersEnabled = enabled;
    }
    /**
    * Admin Only
    **/

    /**
    * If, for some reason, this contract has any tokens 
    * erroneously assigned to it this will allow the 
    * admin to access them. 
    **/
    function recoverErrantTokens( ERC20 token, uint amount ) 
    onlyOwner 
    {
        token.transfer(owner, amount);
    }

    /**
    * As new version of the DRS are released this contract 
    * will need to be updated. 
    **/
    function updateHealthDRS(address _healthDRS, bytes _healthDRSurl)
    onlyOwner
    {
       healthDRS = _healthDRS;
       healthDRSurl = _healthDRSurl;       
    }

}