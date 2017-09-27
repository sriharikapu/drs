pragma solidity ^0.4.11;

import '../../contracts/BurnableToken.sol';

contract HealthCashMock is BurnableToken {

  string public name = "Health Cash";
  string public symbol = "HLTH";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 100;

  function HealthCashMock() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}