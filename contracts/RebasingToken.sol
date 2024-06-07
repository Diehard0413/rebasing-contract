// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRebasingToken.sol";
import "./tokens/extensions/ERC20PresetMinterRebaser.sol";
import "./utils/Ownable.sol";

contract RebasingToken is ERC20PresetMinterRebaser, Ownable, IRebasingToken {
    uint256 private _totalGons;
    uint256 private _gonsPerFragment;
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10 ** 18; // Initial supply of 1,000,000 tokens

    mapping(address => uint256) private _gonBalances;

    constructor() ERC20PresetMinterRebaser("RebasingToken", "RBT") {
        _totalGons = INITIAL_SUPPLY * 10**18; // Initialize total gons
        _gonsPerFragment = _totalGons / INITIAL_SUPPLY; // Initial gons per fragment
        _gonBalances[msg.sender] = _totalGons;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from == address(0) || to == address(0)) return; // Ignore minting and burning
        uint256 gonValue = amount * _gonsPerFragment;
        _gonBalances[from] -= gonValue;
        _gonBalances[to] += gonValue;
    }

    function totalSupply() public view override(ERC20, IRebasingToken) returns (uint256) {
        return _totalGons / _gonsPerFragment;
    }

    function balanceOf(address account) public view override(ERC20, IRebasingToken) returns (uint256) {
        return _gonBalances[account] / _gonsPerFragment;
    }

    function transfer(address recipient, uint256 amount) public override(ERC20, IRebasingToken) returns (bool) {
        uint256 gonValue = amount * _gonsPerFragment;
        _gonBalances[_msgSender()] -= gonValue;
        _gonBalances[recipient] += gonValue;
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20, IRebasingToken) returns (bool) {
        uint256 gonValue = amount * _gonsPerFragment;
        _gonBalances[sender] -= gonValue;
        _gonBalances[recipient] += gonValue;
        return super.transferFrom(sender, recipient, amount);
    }

    function rebase(uint256 newSupply) external onlyOwner override {
        require(newSupply > 0, "New supply must be greater than 0");
        _gonsPerFragment = _totalGons / newSupply;
        _mint(msg.sender, newSupply);
    }
}