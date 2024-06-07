const LPToken = artifacts.require("LPToken");
const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

contract('test for all', async accounts => {
    let lpToken;
    let rebasingToken;
    let contract;

    before(async () => {
        lpToken = await LPToken.deployed();
        rebasingToken = await RebasingToken.deployed();
        contract = await StakingContract.deployed();

        console.log(accounts);

        console.log("LPToken:", lpToken.address);
        console.log("RebasingToken:", rebasingToken.address);
        console.log("StakingContract:", contract.address);
    })

    it('distribution of lp token', async () => {     
        await lpToken.transfer(accounts[1], web3.utils.toBN("100000"), {from: accounts[0]});
        await lpToken.transfer(accounts[2], web3.utils.toBN("200000"), {from: accounts[0]});
    })

    it('distribution of rebasing token', async () => {     
        await rebasingToken.transfer(accounts[1], web3.utils.toBN("100000"), {from: accounts[0]});
        await rebasingToken.transfer(accounts[2], web3.utils.toBN("200000"), {from: accounts[0]});
    })

    it('intialize of staking contract', async () => {

    })
})