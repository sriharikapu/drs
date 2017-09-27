pragma solidity ^0.4.14;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';

contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

  /** How many tokens we burned */
  event Burned(address burner, uint burnedAmount);

  /*
  * Burn extra tokens from a balance.
  */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    Burned(burner, burnAmount);
  }

}