// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRebasingToken.sol";
import "./libraries/SafeMath.sol";
import "./tokens/ERC20.sol";
import "./utils/Ownable.sol";

contract RebasingToken is ERC20, Ownable, IRebasingToken {
    using SafeMath for uint256;

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant MAX_SUPPLY = ~uint128(0);
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10 ** 18;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);

    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedValue;

    constructor() ERC20("RebasingToken", "RBT") {
        _totalSupply = INITIAL_SUPPLY;
        _gonsPerFragment = TOTAL_GONS / INITIAL_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

     function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual override {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function circulatingSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override(IERC20, ERC20) returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    function gonsForBalance(uint256 amount) public view override returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 amount) public view override returns (uint256) {
        return amount.div(_gonsPerFragment);
    }

    function allowance(address owner_, address spender) public view override(IERC20, ERC20) returns (uint256) {
        return _allowedValue[owner_][spender];
    }

    function approve(address spender, uint256 value) public override(IERC20, ERC20) returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override(IERC20, ERC20) returns (bool) {
        uint256 gonValue = amount.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[recipient] = _gonBalances[recipient].add(gonValue);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(IERC20, ERC20) returns (bool) {
        _allowedValue[sender][msg.sender] = _allowedValue[sender][msg.sender].sub(amount);
        emit Approval(sender, msg.sender, _allowedValue[sender][msg.sender]);
        
        uint256 gonValue = gonsForBalance(amount);
        _gonBalances[sender] = _gonBalances[sender].sub(gonValue);
        _gonBalances[recipient] = _gonBalances[sender].add(gonValue);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function rebase(uint256 newSupply) external onlyOwner override {
        require(newSupply > 0, "New supply must be greater than 0");
        _gonsPerFragment = _totalSupply / newSupply;
        _mint(msg.sender, newSupply);
    }    
}