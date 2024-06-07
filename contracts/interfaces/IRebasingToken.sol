// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IRebasingToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function rebase(uint256 newSupply) external;
}