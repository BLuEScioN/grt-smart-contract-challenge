// Get private stuff from my .env file
var env = require('./.env');
var DaiPool = require('./build/contracts/DaiPool.json');
var Cookie = require('./build/contracts/Cookie.json');

var Web3 =  require('Web3');

// Rather than using a local copy of geth, interact with the ethereum blockchain via infura.io
const web3 = new Web3(`https://rinkeby.infura.io/v3/${env.infuraKey}`)

// Create a script to query the total amount of tokens held in the contract and the deposited rewards.
const main = async () => {
    var daiPoolContractAddress = '0xdE82fbc351da35B0edE481F22716e071a1f22701';

    var daiPoolContract = new web3.eth.Contract(DaiPool.abi, daiPoolContractAddress);

    var daiPoolTotalSupply = await daiPoolContract.methods.totalSupply().call();

    console.log('daiPoolTotalSupply', daiPoolTotalSupply)

    var rewardsTokenAddress = '0x64844C518EaC1693196b9908dD5e55F9Be838532'

    var cookieContract = new web3.eth.Contract(Cookie.abi, rewardsTokenAddress);

    var depositedRewards = await cookieContract.methods.balanceOf(daiPoolContractAddress).call();

    console.log('depositedRewards', depositedRewards);
}

main();