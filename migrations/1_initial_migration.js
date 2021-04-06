const DaiPool = artifacts.require("DaiPool");
const Cookie = artifacts.require("Cookie");
const Migrations = artifacts.require('Migrations');

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Migrations);

    deployer.deploy(Cookie, 7000000000)
        .then(function() { 
        console.log("Deployed Cookie")
        console.log("accounts[0]", accounts[0])
        console.log("accounts", accounts)
        const cookieAddress = Cookie.address;
        console.log("cookieAddress", cookieAddress)
        const daiAddress = '0xc3dbf84Abb494ce5199D5d4D815b10EC29529ff8';
        console.log('Deploying DaiPool')
        return deployer.deploy(DaiPool, accounts[0], accounts[0], daiAddress, cookieAddress);
    
    })
};
