require('dotenv').config();
const {
  BN,
  ether
} = require('@openzeppelin/test-helpers');

const Web3 = require('web3');
// Ganache UI on 8545
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

var Vault = artifacts.require("./Vault.sol");
var TestERC20 = artifacts.require("./TestERC.sol");

module.exports = async (deployer, network, accounts) => {

  if (network == "development") {
    const MYERC20_TOKEN_SUPPLY = new BN(5000000);

    await deployer.deploy(TestERC20, "Ibiza Token", "IBZ", MYERC20_TOKEN_SUPPLY);
    const tokenInstance = await TestERC20.deployed();
    console.log('Token Deployed: ', tokenInstance.address);

    await deployer.deploy(Vault , tokenInstance.address, 180, 25, 500000)
    vaultInstance = await Vault.deployed()
    console.log("Vault Deployed: " + vaultInstance.address)
  }
};
