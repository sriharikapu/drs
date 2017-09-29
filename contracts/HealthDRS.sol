pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableToken.sol';

contract HealthDRS is Ownable {

    /**
    * Health Decentralized Record Service (DRS)
    * This contract enables registration and permissioning
    * of gatekeeper services using keys that can be managed,
    * shared, or sold using Health Cash (HLTH). 
    */

    BurnableToken public token;
    uint public registrationPrice = 1; 
    uint16 public version = 1;     
    address public latestContract = address(this);         

    //Gatekeeper service only have a url for now
    struct Gatekeeper {
        string url;         
    }

    //Ring establishes relationships between keys
    struct Ring {
        uint8 distance;
        Gatekeeper gatekeeper;
        bytes32[] keys;
    }
    Ring[] rings;    

    struct Key {
        bytes32 id;         
        address owner;        
        uint primary; 
        uint secondary;        
    }

    mapping(bytes32 => Key) keys;
    mapping(address => bytes32[]) accountKeys;     

    /* 
        Create Keys
            - Create a root key by registering a gatekeeper url
            - Create a peer key 
            - Create a child key
            - Create a shared access key
    */
    event NewKey(bytes32 indexed _key);

    //Create a root key by registering a gatekeeper url    
    function registerGatekeeper(string _url) 
        isAuthorizedToSpend(registrationPrice)    
        returns (bytes32 id)
    {
       //HLTH spent to register are burned
       token.transferFrom(msg.sender, address(this), registrationPrice);
       token.burn(registrationPrice); 

       //create a unique id 
       id = keccak256(_url,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].primary == 0);

       keys[id].id = id;       
       keys[id].owner = msg.sender;       

       //primary ring
       Ring memory primary;
       primary.distance = 0;
       primary.gatekeeper.url = _url;
       keys[id].primary = rings.push(primary) - 1;
       rings[keys[id].primary].keys.push(id);

       //secondary ring
       Ring memory secondary;
       secondary.distance = 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);
       
       NewKey(id);
    }

    //Create a peer key from a key you own
    function createPeerKey(bytes32 _id) returns (bytes32 id) {

       require(msg.sender == keys[_id].owner);

       //create a unique id 
       id = keccak256(_id,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].primary == 0);

       keys[id].id = id;       
       keys[id].owner = msg.sender; 

       //primary is the same
       keys[id].primary = keys[_id].primary;
       rings[keys[id].primary].keys.push(id);

       //new secondary ring
       Ring memory secondary;
       secondary.distance = rings[keys[id].primary].distance + 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);
       accountKeys[msg.sender].push(id);

       NewKey(id);
    }

    //Create a child key from a key you own 
    function createChildKey(bytes32 _id) returns (bytes32 id) {

       require(msg.sender == keys[_id].owner);

       //create a unique id 
       id = keccak256(_id,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].primary == 0);

       keys[id].id = id;       
       keys[id].owner = msg.sender; 


       //primary is parent's secondary
       keys[id].primary = keys[_id].secondary;
       rings[keys[id].primary].keys.push(id);

       //secondary ring
       Ring memory secondary;
       secondary.distance = rings[keys[id].primary].distance + 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);
       NewKey(id);
    }

    // Create a clone key to be able to share access for a key you own
    function createCloneKey(bytes32 _id) returns (bytes32 id) {

       require(msg.sender == keys[_id].owner);

       //create a unique id 
       id = keccak256(_id,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].primary == 0);

       keys[id].id = id;       
       keys[id].owner = msg.sender; 

       //primary is the same
       keys[id].primary = keys[_id].primary;
       rings[keys[id].primary].keys.push(id);   

       //secondary is the same
       keys[id].secondary = keys[_id].secondary;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);

       NewKey(id);
    }

    /** 
    * Sell Keys
    */

    //Offers contain a key id, an address, and a purchase price (HLTH)
    //They can only be created by a key owner
    //To sell you create an offer, and the buyer has to purchase based on the offer 
    //We need a way to retrieve offers made to an address
    //We need to update the owners and the accountKeys mapping

 
    /**
    * Trade Keys
    */

    // Trade offer list will be a mapping of a keys you want
    // with a give you are willing to trade 
    // Where only the owner can add trade offers 
    // When a trade offer is made - we'll look to see if 
    // a matching offer exists and make the trade if so. 
    // This needs to update accountKeys


    /**
    * Manage Keys
    */
    
    //need to be able to remove keys
    //first only allow parent keys to remove keys 
    //peer keys can not remove each other
    //if a key is removed we have to delete it from the accountsKey 
    //mapping, the key mapping, and from any related rings


    /*
    * HLTH tokens can not be spent using HealthDRS 
    * without first authorizing HealthDRS to do so,
    * we need a simple way to check if we are
    * authorize to spend HLTH for the user. 
    */
    modifier isAuthorizedToSpend(uint _value) {
        assert(authorizedToSpend() >= _value); 
        _;
    }
    function authorizedToSpend() constant returns (uint) {
        return token.allowance(msg.sender, address(this)); 
    }



    /**
    * 
    *  Utility functions for interacting with DRS
    * 
    */
    function getKeyOwner(bytes32 id) constant returns (address) {
        return keys[id].owner;
    }

    //Using any key retreive the gatekeeper's url
    function getURL(bytes32 id)
    constant returns (string)
    {
        if (rings[keys[id].primary].distance == 0) {
            return rings[keys[id].primary].gatekeeper.url;
        } else {
            bytes32 keyId;
            for (uint i = 0; i < rings[keys[id].primary].keys.length; i++) {
                keyId = rings[keys[id].primary].keys[i];
                if (rings[keys[keyId].primary].distance < rings[keys[id].primary].distance) {
                    return getURL(keyId);
                }
            }
        }
    }

    //Update a gatekeeper url using key
    function updateGatekeeperUrl(bytes32 id, string url) {
       require(msg.sender == keys[id].owner); //owner only
       require(rings[keys[id].primary].distance == 0); //root key only
       rings[keys[id].primary].gatekeeper.url = url;
    }


    /**
    * [Admin Only] 
    * Allow admin access to tokens transfered to this 
    * contract. 
    */
    function recoverTokens(BurnableToken _token, uint amount) 
    onlyOwner 
    {
        _token.transfer(owner, amount);
    }

    function setRegistrationPrice(uint _price) 
    onlyOwner 
    {
        registrationPrice = _price;
    }
    
    function setHealthCashToken(BurnableToken _token) 
    onlyOwner 
    {
        token = _token;
    }

}