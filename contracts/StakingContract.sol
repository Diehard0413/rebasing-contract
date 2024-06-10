// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC20.sol";
import "./interfaces/IRebasingToken.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./utils/Ownable.sol";

contract StakingContract is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant DENIMINATOR = 100000000;
    uint256 constant YEAR = 365 days;

    IRebasingToken public rebasingToken;
    IERC20 public lpToken;
    address public poolAddress;

    uint256 public fixedAPY = 31536000; // 50% fixed APY (multiply by 100 for percentage)
    uint256 public variableAPYMax = 31536000; // 50% max variable APY
    uint256 public variableAPYMin = 1000; // 10% min variable APY
    uint256 public taxRate = 100; // 1% tax rate (multiply by 100 for percentage)
    
    struct StakerInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => StakerInfo) public stakers;

    uint256 public _lastRewardTime;
    uint256 public _accRewardPerShare;
    uint256 public _totalStaked;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event FixedAPYUpdated(uint256 newVal);
    event VariableAPYUpdated(uint256 newMinVal, uint256 newMaxVal);
    event TaxRateUpdated(uint256 newTaxRate);
    event PoolAddressUpdated(address indexed newPoolAddress);

    constructor(IERC20 _lpToken, IRebasingToken _rebasingToken, address _poolAddress) {
        rebasingToken = _rebasingToken;
        lpToken = _lpToken;
        poolAddress = _poolAddress;
        _lastRewardTime = block.timestamp;
    }

    function setFixedAPY(uint256 _fixedAPY) external onlyOwner {
        fixedAPY = _fixedAPY;
        emit FixedAPYUpdated(_fixedAPY);
    }

    function setVariableAPY(uint256 _max, uint256 _min) external onlyOwner {
        variableAPYMax = _max;
        variableAPYMin = _min;
        emit VariableAPYUpdated(_min, _max);
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        taxRate = _taxRate;
        emit TaxRateUpdated(_taxRate);
    }

    function setPoolAddress(address _poolAddress) external onlyOwner {
        poolAddress = _poolAddress;
        emit PoolAddressUpdated(_poolAddress);
    }

    function stake(uint256 amount) external {
        updateRewards(msg.sender);
        StakerInfo storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            uint256 pending = staker.amount.mul(_accRewardPerShare).div(1e18).sub(staker.rewardDebt);
            if (pending > 0) {
                rebasingToken.transfer(msg.sender, pending);
            }
        }
        if (amount > 0) {
            lpToken.transferFrom(msg.sender, address(this), amount);
            staker.amount = staker.amount.add(amount);
            _totalStaked = _totalStaked.add(amount);
        }
        staker.rewardDebt = staker.amount.mul(_accRewardPerShare).div(1e18);
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        updateRewards(msg.sender);
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.amount >= amount, "Insufficient staked amount");
        uint256 pending = staker.amount.mul(_accRewardPerShare).div(1e18).sub(staker.rewardDebt);
        if (pending > 0) {
            rebasingToken.transfer(msg.sender, pending);
        }
        if (amount > 0) {
            uint256 tax = amount.mul(taxRate).div(DENIMINATOR);
            lpToken.transfer(msg.sender, amount.sub(tax));
            staker.amount = staker.amount.sub(amount);
            _totalStaked = _totalStaked.sub(amount);
        }
        staker.rewardDebt = staker.amount.mul(_accRewardPerShare).div(1e18);
        emit Unstake(msg.sender, amount);
    }

    function claim() external {
        updateRewards(msg.sender);
        StakerInfo storage staker = stakers[msg.sender];
        uint256 pending = staker.amount.mul(_accRewardPerShare).div(1e18).sub(staker.rewardDebt);
        if (pending > 0) {
            rebasingToken.transfer(msg.sender, pending);
            staker.rewardDebt = staker.amount.mul(_accRewardPerShare).div(1e18);
            emit Claim(msg.sender, pending);
        }
    }

    function updateRewards(address stakerAddr) public {
        if (block.timestamp <= _lastRewardTime) {
            return;
        }
        if (_totalStaked == 0) {
            _lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp.sub(_lastRewardTime);
        uint256 fixedReward = _totalStaked.mul(fixedAPY).div(DENIMINATOR).div(YEAR).mul(multiplier);
        uint256 variableAPY = calculateVariableAPY(stakerAddr);
        uint256 variableReward = _totalStaked.mul(variableAPY).div(DENIMINATOR).div(YEAR).mul(multiplier);
        uint256 reward = fixedReward.add(variableReward);
        rebasingToken.rebase(reward, block.timestamp);
        _accRewardPerShare = _accRewardPerShare.add(reward.mul(1e18).div(_totalStaked));
        _lastRewardTime = block.timestamp;
    }

    function calculateVariableAPY(address stakerAddr) public view returns (uint256) {
        StakerInfo storage staker = stakers[stakerAddr];
        uint256 stakedValue = staker.amount.mul(rebasingToken.balanceOf(address(this))).div(rebasingToken.totalSupply());
        uint256 lpValue = lpToken.balanceOf(poolAddress);
        if (lpValue == 0) {
            return variableAPYMax;
        }
        uint256 ratio = stakedValue.mul(1e18).div(lpValue);
        ratio = ratio > 1e18 ? 1e18 : ratio;
        uint256 variableAPY = variableAPYMax.sub(sqrt(ratio).mul(variableAPYMax.sub(variableAPYMin)).div(1e9));
        return variableAPY;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x.add(1)).div(2);
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
        return z;
    }
}