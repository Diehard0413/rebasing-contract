const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

contract('test for all', async accounts => {
    let token;
    let contract;

    before(async () => {
        token = await RebasingToken.deployed();
        contract = await StakingContract.deployed();

        console.log(accounts);

        console.log("RebasingToken:", token.address);
        console.log("StakingContract:", contract.address);
    })

    it('distribution of rebasing token', async () => {     
        await token.mint(accounts[0], web3.utils.toBN("100000"), {from: accounts[0]});
        await token.mint(accounts[1], web3.utils.toBN("200000"), {from: accounts[0]});
    })

    it('intialize of staking contract', async () => {

    })
})