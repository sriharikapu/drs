pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract HealthDRS is Ownable {

    StandardToken public token;

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

    function HealthDRS(StandardToken _token, address admin) {
        token = _token;
        transferOwnership(admin);         
    }


  bytes32[] public keyList;


    //Register a URL - Returns Control Key
    //Using Control Key 
    //create an Access Key
    //Set Price, Address of Valid Purchaser
    //Purchaser 

    function registerRecord(bytes uri) 
    public returns (bytes32) 
    {
       return keccak256(uri);
    }

}