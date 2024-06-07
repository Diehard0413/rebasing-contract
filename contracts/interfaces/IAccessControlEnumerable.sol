// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IAccessControl.sol";

interface IAccessControlEnumerable is IAccessControl {
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}