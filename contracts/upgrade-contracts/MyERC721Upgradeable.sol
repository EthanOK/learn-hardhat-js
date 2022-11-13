// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract MyERC721Upgradeable is ERC721Upgradeable {
    function initialize() public initializer {
        __ERC721_init("AAA", "A");
    }
}
