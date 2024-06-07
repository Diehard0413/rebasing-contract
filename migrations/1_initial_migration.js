const RebasingToken = artifacts.require("RebasingToken");
const StakingContract = artifacts.require("StakingContract");

module.exports = async (deployer) => {
  await deployer.deploy(RebasingToken);
  const token = await RebasingToken.deployed();
  console.log("RebasingToken", token.address);

  await deployer.deploy(StakingContract);
  const contract = await StakingContract.deployed();
  console.log("StakingContract", contract.address);
};

