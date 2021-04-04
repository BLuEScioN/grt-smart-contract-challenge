const DaiPool = artifacts.require("DaiPool");
const ERC20Generator = artifacts.require("ERC20Generator");
const Migrations = artifacts.require('Migrations');

module.exports = function (deployer, network, accounts) {
//   deployer.deploy(DaiPool);
    deployer.deploy(Migrations);
    // deployer.deploy(ERC20Generator, 'Cookie', 'KIE', 8000000000);
    // Deploy ERC20Generator, then deploy DaiPool, passing in ERC20Generator's newly deployed address for the reward token argument
    deployer.deploy(ERC20Generator, 'Cookie', 'KIE', 7000000000).then(function() {
        console.log("Deployed ERC20Generator")
        console.log("accounts[0]", accounts[0])
        console.log("accounts", accounts)
        console.log("ERC20Generator.address", ERC20Generator.address)

        return deployer.deploy(DaiPool, accounts[0], accounts[0], 0xc3dbf84Abb494ce5199D5d4D815b10EC29529ff8, ERC20Generator.address);
    });
};

// _owner,
// address _rewardsDistribution,
// address _stakingToken,
// address _rewardsToken