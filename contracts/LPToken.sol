//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./tokens/extensions/ERC20Burnable.sol";
import "./utils/Ownable.sol";

contract LPToken is ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10 ** 18; // Initial supply of 1,000,000 tokens

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}