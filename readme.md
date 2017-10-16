# Health Nexus :: DRS 
<img align="right" src="./assets/HN_token_transparent.png?raw=true" height="348">
An Ethereum smart-contract for creating a decentralized record service using the EIP 20 token Health Cash (HLTH). This is project is part of phase one of Health Nexus, the public permissioned blockchain for healthcare. 

Features:

* Create services by registering service urls
* Create and issue keys for services
* Permission keys for sharing, selling, and trading
* Share keys with multiple accounts
* Sell keys for Health Cash (HLTH)
* Trade keys

<details>
 <summary><strong>Table of Contents</strong> (click to expand)</summary>

* [Installation](#installation)
* [Testing](#️testing)
* [Notes](#notes)
* [Resources](#resources)
* [Credits](#️credits)
* [License](#license)
</details>

## Installation

To clone and use this smart contract, you'll need [Git](https://git-scm.com) and [Node.js](https://nodejs.org/en/download/) (which comes with [npm](http://npmjs.com)), [Truffle](http://truffleframework.com/), and a local development Ethereum node on your computer ([Geth](https://github.com/ethereum/go-ethereum), [Parity](https://github.com/paritytech/parity)). 

From your command line:

```bash
# Clone this repository
$ git clone https://github.com/Health-Nexus/drs.git

# Go into the repository
$ cd drs

# Install dependencies
$ npm install

# Compile contracts
$ truffle compile

# Deploy contracts
$ truffle migrate
```

## Testing

Running the the test suite requires your dev node have two unlocked accounts provisioned with sufficient ether to pay the transaction costs. About TestRPC, the tests were not written for TestRPC which handles contract throws differently than geth or parity. This is a known [issue](https://github.com/ethereumjs/testrpc/issues/39). 

From your command line:

```bash
# Run Test Suite
$ truffle test
```
