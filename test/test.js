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
        console.log("Owner balance: ", (await lpToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Pool balance: ", (await lpToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("User1 balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log("User2 balance: ", (await lpToken.balanceOf(accounts[3], {from: accounts[0]})).toString());

        await lpToken.transfer(accounts[1], web3.utils.toBN("100000000000000000000000"), {from: accounts[0]});
        await lpToken.transfer(accounts[2], web3.utils.toBN("2000000"), {from: accounts[0]});
        await lpToken.transfer(accounts[3], web3.utils.toBN("3000000"), {from: accounts[0]});
        
        console.log("~~~~~~~~~~LP token's balances after distribution~~~~~~~~~~");
        console.log("Owner balance: ", (await lpToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("Pool balance: ", (await lpToken.balanceOf(accounts[1], {from: accounts[0]})).toString());
        console.log("User1 balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log("User2 balance: ", (await lpToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
    })

    it('distribution of rebasing token', async () => {
        console.log("~~~~~~~~~~Rebasing token's balances before distribution~~~~~~~~~~");
        console.log("Owner balance: ", (await rebasingToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        console.log("User1 balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log("User2 balance: ", (await rebasingToken.balanceOf(accounts[3], {from: accounts[0]})).toString());

        // await rebasingToken.transfer(accounts[2], web3.utils.toBN("100000"), {from: accounts[0]});
        // await rebasingToken.transfer(accounts[3], web3.utils.toBN("200000"), {from: accounts[0]});

        // console.log("~~~~~~~~~~Rebasing token's balances after distribution~~~~~~~~~~");
        // console.log("Owner balance: ", (await rebasingToken.balanceOf(accounts[0], {from: accounts[0]})).toString());
        // console.log("User1 balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        // console.log("User2 balance: ", (await rebasingToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
    })

    it('intialization of staking contract parameters', async () => {
        await rebasingToken.setStakingAddr(stakingContract.address, {from: accounts[0]});
        console.log("Staking contract address was set: ", (await rebasingToken.stakingContract({from: accounts[0]})).toString());

        await stakingContract.setPoolAddress(accounts[2], {from: accounts[0]});
        console.log("Pool contract address was set: ", (await stakingContract.poolAddress({from: accounts[0]})).toString());
    })

    it('staking interaction with staking contract', async () => {
        await lpToken.approve(stakingContract.address, web3.utils.toBN("1000000"), {from: accounts[2]});
        console.log(`LP token allowance from User1 to Staking contract: ${(await lpToken.allowance(accounts[2], stakingContract.address, {from: accounts[0]})).toString()}`);

        await stakingContract.stake(web3.utils.toBN("1000000"), {from: accounts[2]});
        console.log(`User1 Staking info 
            amount: ${(await stakingContract.stakers(accounts[2], {from: accounts[0]})).amount.toString()},
            debt: ${(await stakingContract.stakers(accounts[2], {from: accounts[0]})).rewardDebt.toString()}`);
        
        console.log("User1 Lp token balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log("User1 Rebasing token balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log(`Variable APY for User1: ${(await stakingContract.calculateVariableAPY(accounts[2], {from: accounts[0]})).toString()}`);


        await lpToken.approve(stakingContract.address, web3.utils.toBN("2000000"), {from: accounts[3]});
        console.log(`LP token allowance from User2 to Staking contract: ${(await lpToken.allowance(accounts[3], stakingContract.address, {from: accounts[0]})).toString()}`);

        await stakingContract.stake(web3.utils.toBN("2000000"), {from: accounts[3]});
        console.log(`User2 Staking info 
            amount: ${(await stakingContract.stakers(accounts[3], {from: accounts[0]})).amount.toString()},
            debt: ${(await stakingContract.stakers(accounts[3], {from: accounts[0]})).rewardDebt.toString()}`);
        
        console.log("User2 Lp token balance: ", (await lpToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
        console.log("User2 Rebasing token balance: ", (await rebasingToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
        console.log(`Variable APY for User2: ${(await stakingContract.calculateVariableAPY(accounts[3], {from: accounts[0]})).toString()}`);
    })

    it('simulation of staking period', async () => {
        await new Promise(r => setTimeout(r, 10000));
    })

    it('unstaking interaction with staking contract', async () => {
        const DENIMINATOR = web3.utils.toBN("100000000");
        const YEAR = web3.utils.toBN("31536000");
        const FIXEDAPY = web3.utils.toBN("31536000");
        const VARMAX = web3.utils.toBN("31536000");
        const VARMIN = web3.utils.toBN("1000");

        let ts = await stakingContract._totalStaked({from: accounts[2]});
        let rwt = await stakingContract._lastRewardTime({from: accounts[2]});
        let multiplier = Date.now() / 1000 - rwt;
        let fixedrw = ts * multiplier / FIXEDAPY / DENIMINATOR / YEAR;
        let varapy = await stakingContract.calculateVariableAPY(accounts[2], {from: accounts[2]});
        let varrw = ts * multiplier / varapy / DENIMINATOR / YEAR;
        console.log("User1 update balance: ",
            ts.toString(),
            rwt.toString(),
            multiplier.toString(),
            fixedrw.toString(),
            varapy.toString(),
            varrw.toString()
        );

        let rps = await stakingContract._accRewardPerShare({from: accounts[2]});
        let amount = (await stakingContract.stakers(accounts[2], {from: accounts[0]})).amount;
        let rd = (await stakingContract.stakers(accounts[2], {from: accounts[0]})).rewardDebt;
        let pending = rps * amount / 1e18 - rd;
        console.log("User1 pending balance: ",
            rps.toString(),
            amount.toString(),
            rd.toString(),
            pending.toString()
        );

        console.log(`User1 Staking info 
            amount: ${(await stakingContract.stakers(accounts[2], {from: accounts[0]})).amount.toString()},
            debt: ${(await stakingContract.stakers(accounts[2], {from: accounts[0]})).rewardDebt.toString()}`);
        
        console.log("User1 Lp token balance: ", (await lpToken.balanceOf(accounts[2], {from: accounts[0]})).toString());
        console.log("User1 Rebasing token balance: ", (await rebasingToken.balanceOf(accounts[2], {from: accounts[0]})).toString()); 
        console.log(`Variable APY for User1: ${(await stakingContract.calculateVariableAPY(accounts[2], {from: accounts[0]})).toString()}`);

        await stakingContract.unstake(web3.utils.toBN("2000000"), {from: accounts[3]});
        console.log(`User2 Staking info 
            amount: ${(await stakingContract.stakers(accounts[3], {from: accounts[0]})).amount.toString()},
            debt: ${(await stakingContract.stakers(accounts[3], {from: accounts[0]})).rewardDebt.toString()}`);
        
        console.log("User2 Lp token balance: ", (await lpToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
        console.log("User2 Rebasing token balance: ", (await rebasingToken.balanceOf(accounts[3], {from: accounts[0]})).toString());
        console.log(`Variable APY for User2: ${(await stakingContract.calculateVariableAPY(accounts[3], {from: accounts[0]})).toString()}`);
    })
})