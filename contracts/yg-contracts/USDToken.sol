// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDToken is ERC20 {
    constructor() ERC20("USDT", "USDT") {
        // total
        uint256 total = 1_000_000_000 * 1e18;
        // mint
        _mint(msg.sender, total);
    }
}
