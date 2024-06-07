// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IRebasingToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function rebase(uint256 newSupply) external;
}

library Address {
    error AddressInsufficientBalance(address account);

    error AddressEmptyCode(address target);

    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);

    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    function safeTransfer(IERC20 tokenAddr, address to, uint256 value) internal {
        _callOptionalReturn(tokenAddr, abi.encodeCall(tokenAddr.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 tokenAddr, address from, address to, uint256 value) internal {
        _callOptionalReturn(tokenAddr, abi.encodeCall(tokenAddr.transferFrom, (from, to, value)));
    }

    function safeIncreaseAllowance(IERC20 tokenAddr, address spender, uint256 value) internal {
        uint256 oldAllowance = tokenAddr.allowance(address(this), spender);
        forceApprove(tokenAddr, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(IERC20 tokenAddr, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = tokenAddr.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(tokenAddr, spender, currentAllowance - requestedDecrease);
        }
    }

    function forceApprove(IERC20 tokenAddr, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(tokenAddr.approve, (spender, value));

        if (!_callOptionalReturnBool(tokenAddr, approvalCall)) {
            _callOptionalReturn(tokenAddr, abi.encodeCall(tokenAddr.approve, (spender, 0)));
            _callOptionalReturn(tokenAddr, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 tokenAddr, bytes memory data) private {
        bytes memory returndata = address(tokenAddr).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(tokenAddr));
        }
    }

    function _callOptionalReturnBool(IERC20 tokenAddr, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(tokenAddr).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(tokenAddr).code.length > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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