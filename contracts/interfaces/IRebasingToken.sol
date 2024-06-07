// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20.sol";

interface IRebasingToken is IERC20 {
    event Rebased(uint256 indexed epoch, uint256 rebase, uint256 totalSupply);

    function circulatingSupply() external view returns (uint256);
    function gonsForBalance(uint256 amount) external view returns (uint256);
    function balanceForGons(uint256 gons) external view returns (uint256);
    function rebase(uint256 profit, uint256 epoch) external returns (uint256);
}