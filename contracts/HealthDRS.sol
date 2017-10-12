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

    struct Key {
        address owner;   
        uint8 depth;
        bool shareable;
        bool tradeable;
        bool salable;
        bytes32 parent;
        mapping(bytes32 => bytes32) data;                
    }

    struct SalesOffer {
        address buyer;
        uint price;
    }

    mapping (bytes32 => string) urls;
    mapping(bytes32 => Key) keys;
    mapping(bytes32 => address[]) sharedOwners;    
    mapping(address => bytes32[]) public accountKeys;     
    mapping(bytes32 => SalesOffer) public salesOffers;
    mapping(bytes32 => bytes32) public tradeOffers;    
    address public latestContract = address(this);
    StandardToken public token;
    uint16 public version = 1;     

    event KeyCreated(address indexed _owner, bytes32 indexed _key);
    event KeySold(bytes32 _key, address indexed _seller, address indexed _buyer, uint _price);
    event KeysTraded(bytes32 indexed _key1, bytes32 indexed _key2);
    event KeyMoved(bytes32 indexed _key, bytes32 _from, bytes32 _to);
    event Access(address indexed _owner, bytes32 indexed _from, bytes32 indexed _to, uint _time, string _data);
    event Message(address indexed _owner, bytes32 indexed _from, bytes32 indexed _to, uint _time, string _category, string _data);    
    event Log(address indexed _owner, bytes32 indexed _from, uint _time, string _data);        

    modifier ownsKey(bytes32 key) {
        require(isOwner(key, msg.sender));
        _;
    }
 
    modifier validKey(bytes32 key) {
      require(keys[key].owner != address(0));
      _;
    }

    modifier canSell(bytes32 key) {
      require(keys[key].salable);
      _;
    }

    modifier canTrade(bytes32 key) {
      require(keys[key].tradeable);
      _;
    }

    modifier canShare(bytes32 key) {
      require(keys[key].shareable);
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
        if (keys[key].depth == 0) {
            return urls[key];
        } else {
           return getURL(keys[key].parent);
        }
    }

    //owners of root keys can update the url
    function updateURL(bytes32 key, string url) public ownsKey(key) {
       require(keys[key].depth == 0); //root key only
       urls[key] = url;
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

    function createKey(string url) public {

        bytes32 id = keccak256(url,now,msg.sender);

        //do not recreate keys
        require(keys[id].owner == address(0));
        keys[id].owner = msg.sender;       
        keys[id].depth = 0;
        keys[id].shareable = true;
        keys[id].tradeable = true;
        keys[id].salable = true;
        urls[id] = url; //save the url

        accountKeys[msg.sender].push(id);
        KeyCreated(msg.sender, id);
    }

    function createChildKey(bytes32 key)
        public
        ownsKey(key)
        returns (bytes32 id)
    {
        //depth limited to 100
        require(keys[key].depth < 100); 
        
        //create a unique id 
        id = keccak256(key,now,msg.sender);

        //do not recreate keys
        require(keys[id].owner == address(0));
        keys[id].owner = msg.sender; 
        keys[id].depth = keys[key].depth + 1;
        keys[id].parent = key;

        accountKeys[msg.sender].push(id);
        KeyCreated(msg.sender, id);
    }

    function shareKey(bytes32 key, address account)
        public
        ownsKey(key)
        canShare(key)
    {
        if (isOwner(key, account) == false) {
            sharedOwners[key].push(account);
            accountKeys[account].push(key);            
        }
    }

    function unShareKey(bytes32 key, address account)
        public
        ownsKey(key)
    {
        if (keys[key].owner != account) {
            bool foundKey = false;
            for (uint i = 0; i < sharedOwners[key].length; i++) { 
                if (sharedOwners[key][i] == account) {
                    foundKey = true;
                    break;
                }
            }
            if (foundKey) {
                if (i != sharedOwners[key].length - 1) {
                    sharedOwners[key][i] = sharedOwners[key][sharedOwners[key].length - 1];
                }
                sharedOwners[key].length--;
                removeFromAccountKeys(account, key);                
            }
        }
    }

    /** 
    * Sell Keys
    */
    function createSalesOffer(bytes32 key, address buyer, uint price)
        public
        ownsKey(key)
        canSell(key)
    {
        //cancell trade offer & create sales offer
        tradeOffers[key] = bytes32(0);
        salesOffers[key].buyer = buyer;
        salesOffers[key].price = price;
    }

    function cancelSalesOffer(bytes32 key)
        public
        ownsKey(key)
        canSell(key)        
    {
        salesOffers[key].buyer = address(0);
        salesOffers[key].price = 0;
    }

    function purchaseKey(bytes32 key, uint value) 
        public
        canSell(key)                
    {

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
        canTrade(have)        
        canTrade(want)        
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

    function getKey(bytes32 key) 
        public
        constant
        validKey(key)
        returns(address, uint8, bool, bool, bool, bytes32) 
    {
       return (keys[key].owner, 
               keys[key].depth, 
               keys[key].shareable, 
               keys[key].tradeable, 
               keys[key].salable, 
               keys[key].parent);
    }

    //only allow ancestor to grant/deny permission they have
    function setKeyPermissions(
        bytes32 ancestor, 
        bytes32 descendant, 
        bool shareable, 
        bool tradeable, 
        bool salable)
        public
        ownsKey(ancestor)
        validKey(descendant)
    {
        require(isAncestor(ancestor, descendant));
        
        if (keys[ancestor].shareable) {
            keys[descendant].shareable = shareable;
            //unshare if shared
            if (shareable == false) {
                for (uint i = 0; i < sharedOwners[descendant].length; i++) { 
                    removeFromAccountKeys(sharedOwners[descendant][i], descendant);  
                }
                sharedOwners[descendant].length = 0;
            }
        }

        if (keys[ancestor].tradeable) {
            keys[descendant].tradeable = tradeable;
            //cancel any existing trades
            if (tradeable == false) {
                tradeOffers[descendant] = "";
            }
        }

        if (keys[ancestor].salable) {
            keys[descendant].salable = salable;
            //cancel any existing sales
            if (salable == false) {                
                salesOffers[descendant].buyer = 0;
                salesOffers[descendant].price = 0;
            }            
        }

    }        

    function isOwner(bytes32 key, address account) 
        public 
        constant
        validKey(key)
        returns (bool)
    {
        bool owns = false;
        if (keys[key].owner == account) {
            owns = true;
        }
        if (owns == false && keys[key].shareable) {
            for (uint i = 0; i < sharedOwners[key].length; i++) {
                if (sharedOwners[key][i] == account) {
                    owns = true;
                    break;
                }
           }
        }

        return owns;
    }
   
    /* Recursive implementation limits the
       ancestry dept to around 100, we impose this 
       limit in the createChild function to avoid
       this. 
    */
    function isAncestor(bytes32 ancestor, bytes32 key)
        public 
        constant
        validKey(ancestor)
        validKey(key)        
        returns (bool) 
    {
        if (keys[key].depth == 0) {
            return false;
        } else if (keys[key].parent == ancestor) {
            return true;
        } else {
            return isAncestor(ancestor, keys[key].parent);
        }
    } 

    function moveKey(bytes32 ancestor, bytes32 key, bytes32 destination) 
        public
        ownsKey(ancestor)    
        ownsKey(destination)
    {
        require(isAncestor(ancestor, key));
        keys[key].parent = destination;
    }

    function getAncestorCount(bytes32 key)
        public
        constant
        validKey(key)
        returns(uint) 
    {
       return keys[key].depth;
    }

    function getAncestor(bytes32 key, uint depth)
        public 
        constant
        validKey(key)        
        returns (bytes32)
    {
        require(depth <= getAncestorCount(key));

        if (keys[key].depth == depth) {
            return key;
        } else {
            return getAncestor(keys[key].parent, depth);
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
    * ECRecover
    */
    function recoverAddress(
        bytes32 msgHash, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) 
        constant
        returns (address) 
    {
      return ecrecover(msgHash, v, r, s);
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