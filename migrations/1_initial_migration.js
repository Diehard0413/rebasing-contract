const LPToken = artifacts.require("LPToken");
const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

module.exports = async (deployer) => {
  await deployer.deploy(LPToken);
  const lpToken = await LPToken.deployed();
  console.log("LPToken", lpToken.address);

  await deployer.deploy(RebasingToken);
  const rebasingToken = await RebasingToken.deployed();
  console.log("RebasingToken", rebasingToken.address);

  await deployer.deploy(StakingContract);
  const contract = await StakingContract.deployed();
  console.log("StakingContract", contract.address);
};

