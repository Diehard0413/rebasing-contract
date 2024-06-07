const LPToken = artifacts.require("LPToken");
const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

contract('test for all', async accounts => {
    let lpToken;
    let rebasingToken;
    let stakingContract;

    before(async () => {
        lpToken = await LPToken.deployed();
        rebasingToken = await RebasingToken.deployed();
        stakingContract = await StakingContract.deployed();

        console.log(accounts);

        console.log("LPToken: ", lpToken.address);
        console.log("RebasingToken: ", rebasingToken.address);
        console.log("StakingContract: ", stakingContract.address);
    })

    it('distribution of lp token', async () => {
        console.log("~~~~~~~~~~LP token's balances before distribution~~~~~~~~~~");
        console.log("Account0 balance: ", (await lpToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Account1 balance: ", (await lpToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("Account2 balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());

        await lpToken.transfer(accounts[1], web3.utils.toBN("100000"), {from: accounts[0]});
        await lpToken.transfer(accounts[2], web3.utils.toBN("200000"), {from: accounts[0]});
        
        console.log("~~~~~~~~~~LP token's balances after distribution~~~~~~~~~~");
        console.log("Account0 balance: ", (await lpToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Account1 balance: ", (await lpToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("Account2 balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
    })

    it('distribution of rebasing token', async () => {
        console.log("~~~~~~~~~~Rebasing token's balances before distribution~~~~~~~~~~");
        console.log("Account0 balance: ", (await rebasingToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Account1 balance: ", (await rebasingToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("Account2 balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString());

        await rebasingToken.transfer(accounts[1], web3.utils.toBN("100000"), {from: accounts[0]});
        await rebasingToken.transfer(accounts[2], web3.utils.toBN("200000"), {from: accounts[0]});

        console.log("~~~~~~~~~~Rebasing token's balances after distribution~~~~~~~~~~");
        console.log("Account0 balance: ", (await rebasingToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Account1 balance: ", (await rebasingToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("Account2 balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
    })

    it('intialize of staking contract', async () => {
        await stakingContract.stake(web3.utils.toBN("100"), {from: accounts[1]});
        await stakingContract.stake(web3.utils.toBN("200"), {from: accounts[2]});
    })
})