// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YGToken is ERC20, Ownable {
    constructor(address[5] memory _address) ERC20("YGIO", "YGIO") {
        // total
        uint256 total = 1_000_000_000 * 1e18;
        // mint rate
        uint8[5] memory mintRate = [10, 18, 52, 8, 12];
        // mint
        for (uint256 i = 0; i < _address.length; i++) {
            _mint(_address[i], (total * mintRate[i]) / 100);
        }
    }

    // mint onlyOwner
    function mint(uint256 amount) external onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    // burn
    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
}
