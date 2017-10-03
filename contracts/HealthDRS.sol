pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableToken.sol';

contract HealthDRS is Ownable {

    /**
    * Health Decentralized Record Service (DRS)
    * This contract enables registration and permissioning
    * of gatekeeper services (urls) using keys that can be 
    * managed, shared, traded, and sold using Health Cash (HLTH). 
    */

    BurnableToken public token;
    uint public registrationPrice = 1; 
    uint16 public version = 1;     
    address public latestContract = address(this);         

    struct Ring {
        uint url;
        uint8 distance;
        bytes32[] keys;
    }

    struct Key {
        address owner;        
        uint primary; 
        uint secondary;        
    }

    struct SalesOffer {
        address buyer;
        uint price;
    }

    string[] urls; //gatekeeper services
    Ring[] rings; 
    mapping(bytes32 => Key) keys;
    mapping(address => bytes32[]) public accountKeys;     
    mapping(bytes32 => SalesOffer) public salesOffers;
    mapping(bytes32 => bytes32) public tradeOffers;    

    /**
    * EVENTS
    */
    event KeyCreated(bytes32 indexed _key);
    event KeyTransfered(bytes32 indexed _key, address _old, address _new);
    event KeySold(bytes32 _key, address indexed _seller, address indexed _buyer, uint _price);
    event KeysTraded(bytes32 indexed _key1, bytes32 indexed _key2);
    event KeyMoved(bytes32 indexed _key, bytes32 _from, bytes32 _to);
    event AccessGranted(bytes32 indexed _key, uint _time, bytes32 _ident);

    /* 
        Create Keys
    */
    modifier ownsKey(bytes32 key) {
      require(keys[key].owner == msg.sender);
      _;
    }

    //Create a root key by registering a url    
    function createKey(string url) 
        isAuthorizedToSpend(registrationPrice)    
        returns (bytes32 id)
    {
       //HLTH spent to register are burned
       token.transferFrom(msg.sender, address(this), registrationPrice);
       token.burn(registrationPrice); 

       //create a unique id 
       id = keccak256(url,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].secondary == 0);

       keys[id].owner = msg.sender;       

       //primary ring
       Ring memory primary;
       primary.distance = 0;
       primary.url = urls.push(url) - 1;
       keys[id].primary = rings.push(primary) - 1;
       rings[keys[id].primary].keys.push(id);

       //secondary ring
       Ring memory secondary;
       secondary.distance = 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);
       
       KeyCreated(id);
    }

    //Create a peer key from a key you own
    function createPeerKey(bytes32 _key) 
        ownsKey(_key)
        returns (bytes32 id)
    {
       //create a unique id 
       id = keccak256(_key,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].secondary == 0);

       keys[id].owner = msg.sender; 

       //primary is the same
       keys[id].primary = keys[_key].primary;
       rings[keys[id].primary].keys.push(id);

       //new secondary ring
       Ring memory secondary;
       secondary.distance = rings[keys[id].primary].distance + 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);
       accountKeys[msg.sender].push(id);

       KeyCreated(id);
    }

    //Create a child key from a key you own 
    function createChildKey(bytes32 _key) 
        ownsKey(_key)
        returns (bytes32 id)
    {
       //create a unique id 
       id = keccak256(_key,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].secondary == 0);

       keys[id].owner = msg.sender; 

       //primary is parent's secondary
       keys[id].primary = keys[_key].secondary;
       rings[keys[id].primary].keys.push(id);

       //secondary ring
       Ring memory secondary;
       secondary.distance = rings[keys[id].primary].distance + 1;
       keys[id].secondary = rings.push(secondary) - 1;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);
       KeyCreated(id);
    }

    // Create a clone key, needed to share access for a key you own
    function createCloneKey(bytes32 _key) 
        ownsKey(_key)
        returns (bytes32 id) 
    {
       //create a unique id 
       id = keccak256(_key,now,msg.sender);

       //make sure to not recreate existing keys
       require(keys[id].secondary == 0);

       keys[id].owner = msg.sender; 

       //primary is the same
       keys[id].primary = keys[_key].primary;
       rings[keys[id].primary].keys.push(id);   

       //secondary is the same
       keys[id].secondary = keys[_key].secondary;
       rings[keys[id].secondary].keys.push(id);

       accountKeys[msg.sender].push(id);

       KeyCreated(id);
    }

    /**
    * Share Keys
    */
    function shareKey(bytes32 _key, address account) 
        ownsKey(_key)
        returns (bytes32 id)
    {
        id = createCloneKey(_key);
        transferKey(id, account);
    }

    function transferKey(bytes32 _key, address _newOwner) 
        ownsKey(_key)    
        returns (bool)
    {
       KeyTransfered(_key, keys[_key].owner, _newOwner);

       removeFromAccountKeys(keys[_key].owner, _key);
       accountKeys[_newOwner].push(_key);
       keys[_key].owner = _newOwner; 

       return true;
    }

    /** 
    * Sell Keys
    */
    function createSalesOffer(bytes32 _key, address _buyer, uint _price)
        ownsKey(_key)
    {
        //cancell trade offer & create sales offer
        tradeOffers[_key] = bytes32(0);
        salesOffers[_key].buyer = _buyer;
        salesOffers[_key].price = _price;
    }

    function cancelSalesOffer(bytes32 _key)
        ownsKey(_key)
    {
        salesOffers[_key].buyer = address(0);
        salesOffers[_key].price = 0;
    }

    function purchaseKey(bytes32 _key, uint _value) 
        isAuthorizedToSpend(_value)  
    {
       require(salesOffers[_key].buyer == msg.sender);
       require(salesOffers[_key].price == _value);       

       //price is in HLTH tokens
       token.transferFrom(msg.sender, keys[_key].owner, _value);
       
       KeySold(_key, keys[_key].owner, msg.sender, _value);

       removeFromAccountKeys(keys[_key].owner, _key);
       accountKeys[msg.sender].push(_key);
       keys[_key].owner = msg.sender;
       
       //key is no longer for sale
       salesOffers[_key].buyer = 0;
       salesOffers[_key].price = 0;
    }

 
    /**
    * Trade Keys
    */
    function tradeKey(bytes32 _have, bytes32 _want)
       ownsKey(_have)
    {
       if (tradeOffers[_want] == _have) {
           
           KeysTraded(_want, _have);
           tradeOffers[_want] = ""; //remove the tradeOffer

           //complete the trade
           removeFromAccountKeys(keys[_have].owner, _have);
           removeFromAccountKeys(keys[_want].owner, _want);           
           accountKeys[keys[_want].owner].push(_have);           
           accountKeys[msg.sender].push(_want);                      

           keys[_have].owner = keys[_want].owner;
           keys[_want].owner = msg.sender;

        } else {
            //create a trade offer & cancel sales offer
            cancelSalesOffer(_have);
            tradeOffers[_have] = _want;
        }
    }

    /**
    * Manage Keys
    */
    function canManage(bytes32 _ancestor, bytes32 _key)
        constant
        ownsKey(_ancestor)
        returns (bool)
    {
        if (keys[_ancestor].secondary == keys[_key].primary) {
             return true;
        } else if (rings[keys[_ancestor].secondary].distance > rings[keys[_key].primary].distance) {
            return false;  
        }

        bytes32 id; 
        for (uint i = 0; i < rings[keys[_key].primary].keys.length; i++) {
            id = rings[keys[_key].primary].keys[i];
            if (rings[keys[id].primary].distance < rings[keys[_key].primary].distance) {
                return canManage(_ancestor, id); 
            }                
        }

        return false;
    }   

    //Move a key you can manage under another key you own
    function moveKey(bytes32 ancestorKey, bytes32 keyToMove, bytes32 keyDestination) returns (bool) {

        require(canManage(ancestorKey, keyToMove));
        require(keys[keyDestination].owner == msg.sender);
        require(isSharedKey(keyToMove) == false); //moving shared keys may invalidate the data structure

        KeyMoved(keyToMove, ancestorKey, keyDestination);
        keys[keyToMove].primary = keys[keyDestination].secondary;
    }

    function isSharedKey(bytes32 key) constant returns (bool) {
       
       for (uint i = 0; i < rings[keys[key].primary].keys.length; i++) { 
           if (rings[keys[key].primary].keys[i] != key) {
               if (keys[rings[keys[key].primary].keys[i]].secondary == keys[key].secondary) {
                   return true;
               }
           }
       }

       return false;
    }

    function removeFromAccountKeys(address account, bytes32 key) internal {

       bool foundKey = false;

       for (uint i = 0; i < accountKeys[account].length; i++) { 
           if (accountKeys[account][i] == key) {
               foundKey = true;
               break;
           }
       }
       if (foundKey) {
           if (i != accountKeys[account].length - 1) {
               accountKeys[account][i] = accountKeys[account][accountKeys[account].length - 1];
           }
           accountKeys[account].length--;   
       }
    }

    function getAccountKeysLength(address account) external constant returns(uint) {
        return accountKeys[account].length;
    }

    /**
    * TODO
    * create logging functions to store access requests and data access
    */


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
    function getKeyOwner(bytes32 _key) constant returns (address) {
        return keys[_key].owner;
    }

    //Using any key retreive the gatekeeper's url
    function getURL(bytes32 _key)
    constant returns (string)
    {
        if (rings[keys[_key].primary].distance == 0) {
            return urls[rings[keys[_key].primary].url];
        } else {
            bytes32 id;
            for (uint i = 0; i < rings[keys[_key].primary].keys.length; i++) {
                id = rings[keys[_key].primary].keys[i];
                if (rings[keys[id].primary].distance < rings[keys[_key].primary].distance) {
                    return getURL(id);
                }
            }
        }
    }

    //Update a gatekeeper url using key
    function updateGatekeeperUrl(bytes32 _key, string url) ownsKey(_key) {
       require(rings[keys[_key].primary].distance == 0); //root key only
       urls[rings[keys[_key].primary].url] = url;
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