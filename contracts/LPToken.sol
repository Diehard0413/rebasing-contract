//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";
import "./tokens/extensions/ERC20Burnable.sol";
import "./utils/Context.sol";
import "./utils/Ownable.sol";

contract LPToken is Context, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }
}