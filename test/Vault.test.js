const {
    BN,
    constants,
    ether,
    time,
    balance,
    expectEvent,
    expectRevert
} = require('@openzeppelin/test-helpers');
const {
    expect
} = require('chai');

const timeMachine = require('ganache-time-traveler');

const Web3 = require('web3');
// Ganache UI on 8545
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

const approxeq = (v1, v2, epsilon = 0.001) => Math.abs(v1 - v2) <= epsilon;

var Vault = artifacts.require("./Vault.sol");
var TestERC20 = artifacts.require("./TestERC.sol");

let tokenContract, vaultContract;
let owner, user1, user2, user3, user4;

contract('Vault', function (accounts) {
    // const gasPrice = new BN('1');
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

    owner = accounts[0];
    user1 = accounts[1];
    user2 = accounts[2];
    user3 = accounts[3];
    user4 = accounts[4];

    it('get deployed contracts', async function () {
        tokenContract = await TestERC20.deployed();
        expect(tokenContract.address).to.be.not.equal(ZERO_ADDRESS);
        expect(tokenContract.address).to.match(/0x[0-9a-fA-F]{40}/);
        
        vaultContract = await Vault.deployed();
        expect(vaultContract.address).to.be.not.equal(ZERO_ADDRESS);
        expect(vaultContract.address).to.match(/0x[0-9a-fA-F]{40}/);
    });

    describe('settings', function () {
        let res1, res2, res3, res4;

        it('set tranche in rewards distribution contract', async function () {
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
            await tokenContract.transfer(vaultContract.address, ether('200000'), {from: owner})
            await tokenContract.approve(vaultContract.address, ether('400000'))

            tx = await vaultContract.stake(ether('400000'), {from: owner});

            console.log(await vaultContract.getUserVaultInfo(owner))
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
        });

        it('time passes...', async function () {
            const maturity = Number(time.duration.days(30));
            let block = await web3.eth.getBlockNumber();
            console.log((await web3.eth.getBlock(block)).timestamp)

            await timeMachine.advanceTimeAndBlock(maturity);

            block = await web3.eth.getBlockNumber()
            console.log((await web3.eth.getBlock(block)).timestamp)

            console.log(await vaultContract.getUserVaultInfo(owner))
            tx = await vaultContract.claim({from: owner});
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
        });

        it('set tranche in rewards distribution contract', async function () {
            await tokenContract.approve(vaultContract.address, ether('40000'))

            tx = await vaultContract.stake(ether('40000'), {from: owner});

            console.log(await vaultContract.getUserVaultInfo(owner))
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
        });

        it('time passes...', async function () {
            const maturity = Number(time.duration.days(181));
            let block = await web3.eth.getBlockNumber();
            console.log((await web3.eth.getBlock(block)).timestamp)

            await timeMachine.advanceTimeAndBlock(maturity);

            block = await web3.eth.getBlockNumber()
            console.log((await web3.eth.getBlock(block)).timestamp)

            tx = await vaultContract.claim({from: owner});
            console.log(await vaultContract.getUserVaultInfo(owner))
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
        });

        it('time passes...', async function () {
            const maturity = Number(time.duration.days(31));
            let block = await web3.eth.getBlockNumber();
            console.log((await web3.eth.getBlock(block)).timestamp)

            await timeMachine.advanceTimeAndBlock(maturity);

            block = await web3.eth.getBlockNumber()
            console.log((await web3.eth.getBlock(block)).timestamp)

            tx = await vaultContract.claim({from: owner});
            console.log(await vaultContract.getUserVaultInfo(owner))
            console.log(web3.utils.fromWei(await tokenContract.balanceOf(owner)).toString())
        });

    });

});