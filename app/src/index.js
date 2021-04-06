import Web3 from "web3";
import DaiPool from "../../build/contracts/DaiPool.json";
import Cookie from "../../build/contracts/Cookie.json";

const App = {
  web3: null,
  account: null,
  accounts: null,
  meta: null,
  daiPoolContractAddress: '0xdE82fbc351da35B0edE481F22716e071a1f22701',
  cookieContractAddress: '0x64844C518EaC1693196b9908dD5e55F9Be838532',
  daiContractAddress: '0xc3dbf84abb494ce5199d5d4d815b10ec29529ff8',

  start: async function() {
    const { web3 } = this;

    try {
      this.daiPoolContract = new web3.eth.Contract(
        DaiPool.abi,
        this.daiPoolContractAddress,
      );

      this.cookieContract = new web3.eth.Contract(
        Cookie.abi, 
        this.cookieContractAddress
      )

      this.daiContract = new web3.eth.Contract(
          [{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"addedValue","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"subtractedValue","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"}], 
          this.daiContractAddress
      )

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
      this.accounts = accounts;
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
    
    // Acccounts now exposed
    window.ethereum.on('accountsChanged', function () {
        web3.eth.getAccounts(function (error, accounts) {
            this.account = accounts[0];
            console.log(accounts[0], 'current account after account change');
        });
    });
  },

  stake: async function() {
      try{ 
          console.log('stake')
          console.log('this.account', this.account)
          const daiTotalSupply = await this.daiContract.methods.totalSupply().call();
          console.log('daiTotalSupply', daiTotalSupply)
          const stakeAmount = document.getElementById("stakeAmount").value;
          console.log('stakeAmount', stakeAmount)
          const daiPoolDaiAllowance = await this.daiContract.methods.allowance(this.account, this.daiPoolContractAddress).call();
          console.log('daiPoolDaiAllowance', daiPoolDaiAllowance);
          if (daiPoolDaiAllowance < stakeAmount) {
            await this.daiContract.methods.approve(this.daiPoolContractAddress, daiTotalSupply).send({ from: this.account })
          }
          await this.daiPoolContract.methods.stake(stakeAmount).send({ from: this.account });
      } catch(err) {
          console.error(err)
      }
  }
};

window.App = App;

window.addEventListener("load", async function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    await window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live",);
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"),);
  }

  App.start();
});

