// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC20.sol";
import "./interfaces/IRebasingToken.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import "./utils/Ownable.sol";

contract StakingContract is Ownable {
    using SafeERC20 for IERC20;

    IRebasingToken public stakingToken;
    IERC20 public lpToken;

    uint256 public fixedAPY = 5000; // 50% fixed APY (multiply by 100 for percentage)
    uint256 public variableAPYMax = 5000; // 50% max variable APY
    uint256 public variableAPYMin = 1000; // 10% min variable APY
    uint256 public taxRate = 100; // 1% tax rate (multiply by 100 for percentage)
    
    struct StakerInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => StakerInfo) public stakers;

    uint256 private _lastRewardTime;
    uint256 private _accRewardPerShare;
    uint256 private _totalStaked;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);

    constructor(IRebasingToken _stakingToken, IERC20 _lpToken) {
        stakingToken = _stakingToken;
        lpToken = _lpToken;
        _lastRewardTime = block.timestamp;
    }

    function setFixedAPY(uint256 _fixedAPY) external onlyOwner {
        fixedAPY = _fixedAPY;
    }

    function setVariableAPY(uint256 _max, uint256 _min) external onlyOwner {
        variableAPYMax = _max;
        variableAPYMin = _min;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        taxRate = _taxRate;
    }

    function stake(uint256 amount) external {
        updateRewards();
        StakerInfo storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            uint256 pending = staker.amount * _accRewardPerShare / 1e18 - staker.rewardDebt;
            if (pending > 0) {
                stakingToken.transfer(msg.sender, pending);
            }
        }
        if (amount > 0) {
            stakingToken.transferFrom(msg.sender, address(this), amount);
            staker.amount += amount;
            _totalStaked += amount;
        }
        staker.rewardDebt = staker.amount * _accRewardPerShare / 1e18;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        updateRewards();
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.amount >= amount, "Insufficient staked amount");
        uint256 pending = staker.amount * _accRewardPerShare / 1e18 - staker.rewardDebt;
        if (pending > 0) {
            stakingToken.transfer(msg.sender, pending);
        }
        if (amount > 0) {
            uint256 tax = amount * taxRate / 10000;
            stakingToken.transfer(msg.sender, amount - tax);
            staker.amount -= amount;
            _totalStaked -= amount;
        }
        staker.rewardDebt = staker.amount * _accRewardPerShare / 1e18;
        emit Unstake(msg.sender, amount);
    }

    function claim() external {
        updateRewards();
        StakerInfo storage staker = stakers[msg.sender];
        uint256 pending = staker.amount * _accRewardPerShare / 1e18 - staker.rewardDebt;
        if (pending > 0) {
            stakingToken.transfer(msg.sender, pending);
            staker.rewardDebt = staker.amount * _accRewardPerShare / 1e18;
            emit Claim(msg.sender, pending);
        }
    }

    function updateRewards() public {
        if (block.timestamp <= _lastRewardTime) {
            return;
        }
        if (_totalStaked == 0) {
            _lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp - _lastRewardTime;
        uint256 fixedReward = _totalStaked * fixedAPY / 10000 / 365 days * multiplier;
        uint256 variableAPY = calculateVariableAPY();
        uint256 variableReward = _totalStaked * variableAPY / 10000 / 365 days * multiplier;
        uint256 reward = fixedReward + variableReward;
        stakingToken.rebase(stakingToken.totalSupply() + reward);
        _accRewardPerShare += reward * 1e18 / _totalStaked;
        _lastRewardTime = block.timestamp;
    }

    function calculateVariableAPY() public view returns (uint256) {
        uint256 stakedValue = _totalStaked * stakingToken.balanceOf(address(this)) / stakingToken.totalSupply();
        uint256 lpValue = lpToken.balanceOf(address(this));
        if (lpValue == 0) {
            return variableAPYMax;
        }
        uint256 ratio = stakedValue * 1e18 / lpValue;
        ratio = ratio > 1e18 ? 1e18 : ratio;
        return variableAPYMax + (variableAPYMin - variableAPYMax) * sqrt(ratio) / 1e9;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return z;
    }
}