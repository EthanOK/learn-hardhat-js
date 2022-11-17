// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

contract ERC721ConsecutiveTest is ERC721Consecutive {
    constructor() ERC721("YGG", "YG") {}
}
