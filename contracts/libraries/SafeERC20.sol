// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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