pragma solidity 0.4.15;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableToken.sol';

/**
* Health Decentralized Record Service (DRS)
* This contract enables creation of url/key sets which can
* be managed, shared, traded, and sold using Health Cash (HLTH).
*/

contract HealthDRS is Ownable {
    
    struct Key {
        address owner;        
        uint primary; 
        uint secondary;
        mapping(bytes32 => bytes32) data;
    }

    struct Ring {
        uint url;
        uint8 distance;
        bytes32[] keys;
    }

    struct SalesOffer {
        address buyer;
        uint price;
    }

    BurnableToken public token;
    uint16 public version = 1;     
    address public latestContract = address(this);         
    string[] urls;
    Ring[] rings; 
    mapping(bytes32 => Key) keys;
    mapping(address => bytes32[]) public accountKeys;     
    mapping(bytes32 => SalesOffer) public salesOffers;
    mapping(bytes32 => bytes32) public tradeOffers;    
    
    event KeyCreated(bytes32 indexed _key);
    event KeyTransfered(bytes32 indexed _key, address _old, address _new);
    event KeySold(bytes32 _key, address indexed _seller, address indexed _buyer, uint _price);
    event KeysTraded(bytes32 indexed _key1, bytes32 indexed _key2);
    event KeyMoved(bytes32 indexed _key, bytes32 _from, bytes32 _to);
    event Access(address indexed _owner, bytes32 indexed _from, bytes32 indexed _to, uint _time, string _data);
    event Message(address indexed _owner, bytes32 indexed _from, bytes32 indexed _to, uint _time, string _category, string _data);    
    event Log(address indexed _owner, bytes32 indexed _from, uint _time, string _data);        

    modifier ownsKey(bytes32 key) {
      require(keys[key].owner == msg.sender);
      _;
    }
 
    modifier validKey(bytes32 key) {
      require(keys[key].secondary > 0);
      _;
    }

    /**
    * URLs 
    */
    function getURL(bytes32 key) 
        public 
        constant 
        validKey(key) 
        returns (string) 
    {
        if (rings[keys[key].primary].distance == 0) {
            return urls[rings[keys[key].primary].url];
        } else {
            bytes32 id;
            for (uint i = 0; i < rings[keys[key].primary].keys.length; i++) {
                id = rings[keys[key].primary].keys[i];
                if (rings[keys[id].primary].distance < rings[keys[key].primary].distance) {
                    return getURL(id);
                }
            }
        }
    }

    function updateURL(bytes32 key, string url) public ownsKey(key) {
       require(rings[keys[key].primary].distance == 0); //root key only
       urls[rings[keys[key].primary].url] = url;
    }

    // HLTH tokens can not be spent without
    // first authorizing this contract
    function authorizedToSpend() public constant returns (uint) {
        return token.allowance(msg.sender, address(this)); 
    }

    //Allow admin access to tokens erroneously transfered to this contract
    function recoverTokens(BurnableToken _token, uint amount) public onlyOwner {
        _token.transfer(owner, amount);
    }
   
    function setHealthCashToken(BurnableToken _token) public onlyOwner {
        token = _token;
    }

    function setLatestContract(address _contract) public onlyOwner {
        latestContract = _contract;
    }

    /*  
    * Create Keys
    * root, peer, child, and shared keys 
    */
    function createKey(string url) public returns (bytes32 id) {

        id = keccak256(url,now,msg.sender);

        //do not recreate keys
        require(keys[id].secondary == 0);
        keys[id].owner = msg.sender;       

        /**
        * Rings are used to establish relationships
        * between keys and provide iteration over 
        * related keys.
        *
        * All keys are stored in the keys array
        * and all rings are stored in the rings array. 
        * We store the index to the rings inside the key
        * and the index to the keys inside the rings. 
        */
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

        accountKeys[msg.sender].push(id); //also tracks keys by address
        KeyCreated(id);
    }

    //Create a peer key from a key you own
    function createPeerKey(bytes32 key)
        public 
        ownsKey(key)
        returns (bytes32 id)
    {
       //create a unique id 
       id = keccak256(key,now,msg.sender);

        //do not recreate keys
        require(keys[id].secondary == 0);

       keys[id].owner = msg.sender; 

       //primary is the same
       keys[id].primary = keys[key].primary;
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
    function createChildKey(bytes32 key)
        public
        ownsKey(key)
        returns (bytes32 id)
    {
        //create a unique id 
        id = keccak256(key,now,msg.sender);

        //do not recreate keys
        require(keys[id].secondary == 0);

        keys[id].owner = msg.sender; 

        //primary is parent's secondary
        keys[id].primary = keys[key].secondary;
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
    function createCloneKey(bytes32 key)
        public
        ownsKey(key)
        returns (bytes32 id) 
    {
        //create a unique id 
        id = keccak256(key,now,msg.sender);

        //do not recreate keys
        require(keys[id].secondary == 0);

        keys[id].owner = msg.sender; 

        //primary is the same
        keys[id].primary = keys[key].primary;
        rings[keys[id].primary].keys.push(id);   

        //secondary is the same
        keys[id].secondary = keys[key].secondary;
        rings[keys[id].secondary].keys.push(id);

        accountKeys[msg.sender].push(id);

        KeyCreated(id);
    }

    /**
    * Share Keys
    * Enables multiple accounts to have the same access
    * and to manage the same set of descendant keys
    */
    function shareKey(bytes32 key, address account)
        public
        ownsKey(key)
        returns (bytes32 id)
    {
        id = createCloneKey(key);
        transferKey(id, account);
    }

    function transferKey(bytes32 key, address newOwner)
        public
        ownsKey(key)    
        returns (bool)
    {
       KeyTransfered(key, keys[key].owner, newOwner);

       removeFromAccountKeys(keys[key].owner, key);
       accountKeys[newOwner].push(key);
       keys[key].owner = newOwner; 

       return true;
    }

    /** 
    * Sell Keys
    */
    function createSalesOffer(bytes32 key, address buyer, uint price)
        public
        ownsKey(key)
    {
        //cancell trade offer & create sales offer
        tradeOffers[key] = bytes32(0);
        salesOffers[key].buyer = buyer;
        salesOffers[key].price = price;
    }

    function cancelSalesOffer(bytes32 key)
        public
        ownsKey(key)
    {
        salesOffers[key].buyer = address(0);
        salesOffers[key].price = 0;
    }

    function purchaseKey(bytes32 key, uint value) public {

       //require explictit authority to spend tokens on the purchasers behalf
       require(value <= authorizedToSpend()); 
       require(salesOffers[key].buyer == msg.sender);
       require(salesOffers[key].price == value);       

       //price is in HLTH tokens
       token.transferFrom(msg.sender, keys[key].owner, value);
       
       KeySold(key, keys[key].owner, msg.sender, value);

       removeFromAccountKeys(keys[key].owner, key);
       accountKeys[msg.sender].push(key);
       keys[key].owner = msg.sender;
       
       //key is no longer for sale
       salesOffers[key].buyer = 0;
       salesOffers[key].price = 0;
    }
 
    /**
    * Trade Keys
    */
    function tradeKey(bytes32 have, bytes32 want)
        public
        ownsKey(have)
    {
       if (tradeOffers[want] == have) {
           
           KeysTraded(want, have);
           tradeOffers[want] = ""; //remove the tradeOffer

           //complete the trade
           removeFromAccountKeys(keys[have].owner, have);
           removeFromAccountKeys(keys[want].owner, want);           
           accountKeys[keys[want].owner].push(have);           
           accountKeys[msg.sender].push(want);                      

           keys[have].owner = keys[want].owner;
           keys[want].owner = msg.sender;

        } else {
            //create a trade offer & cancel sales offer
            cancelSalesOffer(have);
            tradeOffers[have] = want;
        }
    }

    /**
    * Manage Keys
    * manage, update, and inspect keys
    */
    function getKeyOwner(bytes32 key) 
        public
        constant
        validKey(key)
        returns (address) 
    {
        return keys[key].owner;
    }

    function isAncestor(bytes32 ancestor, bytes32 key)
        public 
        constant
        validKey(ancestor)
        validKey(key)        
        returns (bool) 
    {
        
        if (keys[ancestor].secondary == keys[key].primary) {
             return true;
        } else if (rings[keys[ancestor].secondary].distance > rings[keys[key].primary].distance) {
            return false;  
        }

        bytes32 id; 
        for (uint i = 0; i < rings[keys[key].primary].keys.length; i++) {
            id = rings[keys[key].primary].keys[i];
            if (rings[keys[id].primary].distance < rings[keys[key].primary].distance) {
                return isAncestor(ancestor, id); 
            }                
        }

        return false;
    }   

    //Move a key you can manage under another key you own
    function moveKey(bytes32 keyAncestor, bytes32 keyToMove, bytes32 keyDestination) 
        public
        ownsKey(keyAncestor)    
        ownsKey(keyDestination)
        returns (bool) 
    {
        require(isAncestor(keyAncestor, keyToMove));

        //move key and all shared keys
        bytes32[] memory primaryKeys = rings[keys[keyToMove].primary].keys;
        uint secondary = keys[keyToMove].secondary;
        for (uint i = 0; i < primaryKeys.length; i++) { 
            if (keys[primaryKeys[i]].secondary == secondary) {
                moveKeyUnder(primaryKeys[i], keyDestination);
                KeyMoved(primaryKeys[i], keyAncestor, keyDestination);
            }
        }
    }

    function getAccountKeysLength(address account) public constant returns(uint) {
        return accountKeys[account].length;
    }

    function getPrimaryKeys(bytes32 key) 
        public 
        constant
        ownsKey(key)
        returns(bytes32[])
    {
        return rings[keys[key].primary].keys;
    }

    function getSecondaryKeys(bytes32 key) 
        public 
        constant
        ownsKey(key)
        returns(bytes32[])
    {
        return rings[keys[key].secondary].keys;
    }

    function getAncestorCount(bytes32 descendant)
        public
        constant
        validKey(descendant)
        returns(uint) 
    {
       return rings[keys[descendant].primary].distance;
    }

    function getAncestor(bytes32 key, uint distance)
        public 
        constant
        validKey(key)        
        returns (bytes32)
    {
        require(distance <= getAncestorCount(key));

        if (rings[keys[key].primary].distance == distance) {
            return key;
        } else {
            bytes32 id;
            for (uint i = 0; i < rings[keys[key].primary].keys.length; i++) {
                id = rings[keys[key].primary].keys[i];
                if (rings[keys[id].primary].distance < rings[keys[key].primary].distance) {
                    return getAncestor(id, distance);
                }
            }
        }
    }

    function moveKeyUnder(bytes32 key, bytes32 destination) private {
        removeKeyFromItsPrimaryRing(key);
        keys[key].primary = keys[destination].secondary;
        rings[keys[key].primary].keys.push(key);  
    }

    function removeKeyFromItsPrimaryRing(bytes32 key) private {
       
       bool foundKey = false;

       for (uint i = 0; i < rings[keys[key].primary].keys.length; i++) { 
           if (rings[keys[key].primary].keys[i] == key) {
               foundKey = true;
               break;
           }
       }
       if (foundKey) {
           if (i != rings[keys[key].primary].keys.length - 1) {
               rings[keys[key].primary].keys[i] = rings[keys[key].primary].keys[rings[keys[key].primary].keys.length - 1];  
           }
           rings[keys[key].primary].keys.length--;   
       }
    }

    function removeFromAccountKeys(address account, bytes32 key) private {

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

    /**
    * Key Data 
    * data, such as permissions, can be stored 
    * on the blockchain for any of your descendant keys
    */
    function getKeyData(bytes32 ancestor, bytes32 child, bytes32 dataKey)
        public
        constant
        ownsKey(ancestor)        
        returns (bytes32)
    {
        require(isAncestor(ancestor, child));
        return keys[child].data[dataKey];
    }

    function setKeyData(bytes32 ancestor, bytes32 child, bytes32 dataKey, bytes32 dataValue)
        public
        ownsKey(ancestor)        
    {
        require(isAncestor(ancestor, child));
        keys[child].data[dataKey] = dataValue;
    }

    /**
    * Logging & Messaging
    * functions for creating an auditable record of activity
    */
    function logAccess(bytes32 from, bytes32 to, string data)
        public
        ownsKey(from)
        validKey(to)        
    {
        require(isAncestor(from, to));
        Access(msg.sender, from, to, now, data);
    }

    function message(bytes32 from, bytes32 to, string category, string data)
        public
        ownsKey(from)
        validKey(to)
    {
        Message(msg.sender, from, to, now, category, data);
    }

    function log(bytes32 from, string data)
        public
        ownsKey(from)            
    {
        Log(msg.sender, from, now, data);
    }

}