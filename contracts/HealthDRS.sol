pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableToken.sol';

contract HealthDRS is Ownable {

    BurnableToken public token;
    uint public registrationPrice = 1; 


    struct Key {
        bytes32 key;         
        address owner;        
        address authorizedToPurchase;
        uint price;
        //--
        Ring ring; 
    }

    struct Ring {
        bytes url;        

    }
    bytes32[] public keyList;

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

    //Register a Gatekeeper by its URL
    //Using Control Key 
    //create an Access Key
    //Set Price, Address of Valid Purchaser
    //Purchaser 

    function registerGatekeeper(bytes url) 
    isAuthorizedToSpend(registrationPrice)
    returns (bytes32) 
    {
       bytes32 key = keccak256(url);

       //HLTH spent to register are burned
       token.transferFrom(msg.sender, address(this), registrationPrice);
       token.burn(registrationPrice); 

       return key;
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