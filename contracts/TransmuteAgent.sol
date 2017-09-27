pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableToken.sol';

contract TransmuteAgent is Ownable {

    /**
    * This contract handles the ethereum 
    * part of transmuting a token cross-chain
    */

    BurnableToken public token;
    bool public enabled = false;
    uint public transmuteNonce = 0; 

    /**
    The event that will trigger the allocation on 
    the other chain
    */
    event Transmute(address indexed _from, address indexed _to, uint _value, bytes32 _id);

    /*
    * Tokens can not be transmuted without 
    * first authorizing the transmute agent 
    * to do so, we need a simple way to 
    * check if we are authorize to spend the
    * token for the user. 
    */
    modifier isAuthorizedToSpend(uint _value) {
        assert(authorizedToSpend() >= _value); 
        _;
    }
    function authorizedToSpend() constant returns (uint) {
        return token.allowance(msg.sender, address(this)); 
    }

    /**
    * Cross-chain transmution burns the original
    * tokens. 
    */
    function transmuteToken(address _to, uint _value) 
    isAuthorizedToSpend(_value)
    returns (bool) 
    {
        require(enabled);
        assert(token.transferFrom(msg.sender, address(this), _value));        
        token.burn(_value);
        transmuteNonce += 1;
        bytes32 id = keccak256(now,transmuteNonce,_to);
        Transmute(msg.sender, _to, _value, id);
        return true;
    }

    /**
    * [Admin Only]
    * set the token contract we are going to transmute from
    */   
    function setTokenToTransmute(BurnableToken _token) 
    onlyOwner 
    {
        token = _token;
    }

    /**
    * [Admin Only]
    * enable/disable 
    */
    function enable(bool _enabled) 
    onlyOwner 
    {
        enabled = _enabled;
    }

}