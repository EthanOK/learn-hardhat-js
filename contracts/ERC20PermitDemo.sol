// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract ERC20PermitDemo is ERC20Permit {
    constructor() ERC20Permit("Permit") ERC20("P", "P") {}

    function transferFromNoApprove(
        address owner,
        address spender,
        uint256 value,
        address to,
        uint256 toValue,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        permit(owner, spender, value, deadline, v, r, s);
        transferFrom(owner, to, toValue);
        return true;
    }
}
