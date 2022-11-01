// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract ERC721AQueryableTest is ERC721AQueryable {
    string baseURI =
        "ipfs://bafybeibnjk2a57x2sgil3yfxck4mqxjgo4ngyyp52kaiax63l5ty4fgf2q";

    constructor() ERC721A("ERC721ATest", "ERC721AT") {}

    function mint(uint256 quantity) external payable {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, quantity);
    }

    // override _startTokenId(default: tokenId start 0)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // override _baseURI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // override tokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, "/", _toString(tokenId)))
                : "";
    }
}
