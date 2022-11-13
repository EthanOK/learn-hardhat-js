// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MyERC20Upgradeable is ERC20Upgradeable {
    function initialize() external initializer {
        __ERC20_init("MyERC20Up", "MEU");
        _mint(msg.sender, 10000 * 1e18);
    }

    function initializeV2() external reinitializer(2) {
        __ERC20_init("MyERC20Up_v2", "MEU");
        _mint(msg.sender, 10000 * 1e18);
    }

    function getInitializedVersion() external view returns (uint8) {
        return _getInitializedVersion();
    }
}
