
## Health Cash :: DRS

This solidity smart contract provides the functionality needed to manage the keys used in a decentralized record system. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

### Prerequisites

To run this locally you will need the [Truffle framework](http://truffleframework.com/), node.js, npm, and a local development ethereum node


### Installing

Install truffle

```

$ npm install -g truffle

```

Once you have cloned the project, from inside the project directory you'll need to run npm install to get the 
testing libraries. 

```

$ npm install

```

Start up your ethereum node then compile and deploy your contracts. You'll need two unlocked accounts on your
ethereum client to be able to run the token transfer tests successfully.

```

$ truffle compile
$ truffle migrate

```


## Running the tests

Once the contracts are deployed to your development ethereum node you can run the test like this. 

```

$ truffle test

```

### Test Overview




## Authors

* **David Akers** - *Initial work* - [davidmichaelakers](https://github.com/davidmichaelakers)


## Acknowledgments

* [SimplyVital Health](https://www.simplyvitalhealth.com/)