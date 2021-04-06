DaiPool Staking Contract

Putting the name aside, DaiPool is a general smart contract for staking an ERC20 token and earning rewards in ERC20 tokens. 

Setup

Create a .env.js file. This file will hold sensitive information about the wallet that you will need to use to send transactions. It will take the form:

module.exports = {
  infuraKey: '<infuraKey>',
  mnemonic: '<mnemonic>'
};

Replace <infuraKey> and <mnemonic> with your own Infura key and MetaMask wallet mnemonic, respectively. 

Deploy the DaiPool Contract to some Ethereum network. Rinkeby, for example. Run 'truffle migrate --network rinkeby'.

You can modify the initialization parameters for the DaiPool Contract in 1_inital_migration.js

This is the constructor for the DaiPool contract:

constructor(
    address _owner,
    address _rewardsDistribution,
    address _stakingToken,
    address _rewardsToken
) Owned(_owner) {
    stakingToken = IERC20(_stakingToken);
    rewardsToken = IERC20Burnable(_rewardsToken);
    rewardsDistribution = _rewardsDistribution; // the wallet that provides the rewards 
}

Set _owner and_rewardsDistribution to the wallet address from which you will be deploying the contract.
Set _stakingToken to the ERC20 that users will be required to stake to earn the reward token. 
This can be any ERC20 token. Note that in order to stake you will have to approve the DaiPool contract to spend your wallet's ERC20 tokens.
You can do this through Remix, Etherscan, your own front-end, etc. There is a front-end built just for this purpose in this repo (although you will have to find and replace some address values to get it to work for your specific needs).
To build the front-end, run 'npm run build'.
To serve the front-end on localhost, run 'npm run dev'.
Set the _rewardToken to the ERC20 that users will be rewarded for staking the _stakingToken. I wrote a Cookie ERC20 contract that you can use for the reward token if you wish. Deploying it with your wallet with give you the total supply of the token,
which will make it easier to finish setting up the DaiPool contract.

Send whatever ERC20 token you want for the reward token to the DaiPool contract.
Then call the DaiPool contract's notifyRewardAmount, and specify a reward less than or equal to the number of tokens you sent for this purpose.

After calling notifyRewardAmount, the DaiPool contract will be set up and active.

There is also a node js script, DaiPoolScript that you can modify to your needs if you want to query your contracts.
