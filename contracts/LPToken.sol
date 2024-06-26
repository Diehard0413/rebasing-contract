//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./tokens/ERC20.sol";
import "./utils/Ownable.sol";

contract LPToken is ERC20, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10 ** 18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}