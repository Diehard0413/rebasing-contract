const LPToken = artifacts.require("LPToken");
const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

module.exports = async (deployer) => {
  await deployer.deploy(LPToken, "LPToken", "LPT");
  const lpToken = await LPToken.deployed();
  console.log("LPToken", lpToken.address);

  await deployer.deploy(RebasingToken);
  const rebasingToken = await RebasingToken.deployed();
  console.log("RebasingToken", rebasingToken.address);

  await deployer.deploy(StakingContract, lpToken.address, rebasingToken.address, rebasingToken.address);
  const stakingContract = await StakingContract.deployed();
  console.log("StakingContract", stakingContract.address);
};

