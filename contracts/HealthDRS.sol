pragma solidity 0.4.15;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';

/**
* Health Decentralized Record Service (DRS)
* This contract enables creation of url/key sets which can
* be managed, shared, traded, and sold using Health Cash (HLTH).
* 
* These url/key sets enable data gatekeeper services and 
* cryptographically secure data exchanges. 
*/

contract HealthDRS is Ownable {

    /*  
    *  Keys are owned by accounts. 
    *
    *  Rings are used to establish relationships
    *  between keys and provide iteration over 
    *  related keys.
    *
    *  All keys are stored in the keys mapping
    *  and all rings are stored in the rings array. 
    *  Ring index is stored inside the key as primary
    *  and secondary ring and the Key's key/hash is 
    *  stored inside the ring's keys array. 
    *
    *  This structure lets us create branching
    *  relationships represented in further comments as
    *  a-z for keys and |(x) for rings at the optionally 
    *  specified distance (x).
    */

    struct Key {
        address owner;        
        uint primary; 
        uint secondary;
        mapping(bytes32 => bytes32) data;
    }

    struct Ring {
        uint url;
        uint distance;
        bytes32[] keys;
    }

    struct SalesOffer {
        address buyer;
        uint price;
    }

    string[] urls;
    Ring[] rings; 
    mapping(bytes32 => Key) keys;
    mapping(address => bytes32[]) public accountKeys;     
    mapping(bytes32 => SalesOffer) public salesOffers;
    mapping(bytes32 => bytes32) public tradeOffers;    
    address public latestContract = address(this);
    StandardToken public token;
    uint16 public version = 1;     

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
    * used to refrence gatekeeper services
    * which use these keys to permission access
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

    //owners of root keys can update the url
    function updateURL(bytes32 key, string url) public ownsKey(key) {
       require(rings[keys[key].primary].distance == 0); //root key only
       urls[rings[keys[key].primary].url] = url;
    }

    //to purchase keys a user must authorize this contract to spend HLTH
    function authorizedToSpend() public constant returns (uint) {
        return token.allowance(msg.sender, address(this)); 
    }

    //allow owner access to tokens erroneously transfered to this contract
    function recoverTokens(StandardToken _token, uint amount) public onlyOwner {
        _token.transfer(owner, amount);
    }
   
    function setHealthCashToken(StandardToken _token) public onlyOwner {
        token = _token;
    }

    function setLatestContract(address _contract) public onlyOwner {
        latestContract = _contract;
    }


    /* createKey
    *  takes a url and returns a key on a root 
    *  ring (0), that has a secondary ring (1).
    *
    *           |(0)
    *           k
    *           |(1)
    */
    function createKey(string url) public returns (bytes32 id) {

        id = keccak256(url,now,msg.sender);

        //do not recreate keys
        require(keys[id].secondary == 0);
        keys[id].owner = msg.sender;       

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

    /* createPeerKey
    *  takes a key (x) returns a key (y) on the
    *  same primary ring, creating a new secondary
    *  ring. 
    *
    *         |
    *        x y
    *        | |
    */
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

    /* createChildKey
    *  takes a key (x) you own and returns 
    *  a key (y), creating a new secondary key. 
    *  x's secondary ring and y's primary ring
    *  are the same
    * 
    *         |
    *         x 
    *         | 
    *         y
    *         | 
    */
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

    /* createCloneKey
    *  takes a key (x) you own and returns 
    *  a key (y) creating no new rings. This
    *  is used to share a key's acess with 
    *  other accounts. 
    *
    *         |
    *        x y
    *         | 
    */
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
    * Creates a clone key as above, then assigns
    * ownership to another account. 
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
    {
       KeyTransfered(key, keys[key].owner, newOwner);

       removeFromAccountKeys(keys[key].owner, key);
       accountKeys[newOwner].push(key);
       keys[key].owner = newOwner; 
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
       assert(token.transferFrom(msg.sender, keys[key].owner, value));
       
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

    //note: recursive implementation limits the
    //ancestry dept to around 100, well more than
    //the expected need
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

    /* moveKey
    *  takes a key (x) you own and moves 
    *  a descendant key (y) to another key
    *  (z) you own. Also moves clone keys
    *  (c).
    *
    *   Before     After
    *      |         |
    *    x   z     x   z 
    *    |   |     |   |
    *   y c           y c
    *    |             |
    *            
    */
    function moveKey(bytes32 ancestor, bytes32 key, bytes32 destination) 
        public
        ownsKey(ancestor)    
        ownsKey(destination)
    {
        require(isAncestor(ancestor, key));

        //move key and all shared keys
        bytes32[] memory primaryKeys = rings[keys[key].primary].keys;
        uint secondary = keys[key].secondary;
        for (uint i = 0; i < primaryKeys.length; i++) { 
            if (keys[primaryKeys[i]].secondary == secondary) {
                moveKeyUnder(primaryKeys[i], destination);
                KeyMoved(primaryKeys[i], ancestor, destination);
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