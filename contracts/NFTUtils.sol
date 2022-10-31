// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTUtils {
    function tokenURI(address contactAddr, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.tokenURI(tokenId);
    }

    function balanceOf(address contactAddr, address account)
        external
        view
        returns (uint256)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.balanceOf(account);
    }

    function ownerOf(address contactAddr, uint256 tokenId)
        external
        view
        returns (address)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.ownerOf(tokenId);
    }

    // Account is owner(tokenId)?
    function tokenIdIsAccount(
        address contactAddr,
        uint256 tokenId,
        address account
    ) external view returns (bool) {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return account == erc721.ownerOf(tokenId);
    }

    //get name and symbol
    function nameAndsymbol(address contactAddr)
        external
        view
        returns (string memory, string memory)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return (erc721.name(), erc721.symbol());
    }

    function getApproved(address contactAddr, uint256 tokenId)
        external
        view
        returns (address)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.getApproved(tokenId);
    }

    function isApprovedForAll(
        address contactAddr,
        address owner,
        address operator
    ) external view returns (bool) {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.isApprovedForAll(owner, operator);
    }

    //
    function supportsInterface(address contactAddr, bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        return erc721.supportsInterface(interfaceId);
    }

    function totalSupply(address contactAddr) external view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        return erc721.totalSupply();
    }

    function tokenOfOwnerByIndex(
        address contactAddr,
        address owner,
        uint256 index
    ) external view OnlyTotalSupply(contactAddr) returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        return erc721.tokenOfOwnerByIndex(owner, index);
    }

    function tokenByIndex(address contactAddr, uint256 index)
        external
        view
        OnlyTotalSupply(contactAddr)
        returns (uint256)
    {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        return erc721.tokenByIndex(index);
    }

    modifier OnlyTotalSupply(address contactAddr) {
        require(
            IERC721Enumerable(contactAddr).totalSupply() > 0,
            "TotalSupply Zero."
        );
        _;
    }

    // ERC20 totalSupply
    function totalSupplyERC20(address erc20Contract)
        external
        view
        returns (uint256)
    {
        IERC20 erc20 = IERC20(erc20Contract);
        return erc20.totalSupply();
    }

    // ERC20 balanceOf
    function balanceOfERC20(address erc20Contract, address account)
        external
        view
        returns (uint256)
    {
        IERC20 erc20 = IERC20(erc20Contract);
        return erc20.balanceOf(account);
    }

    // ERC20 allowance
    function allowanceERC20(
        address erc20Contract,
        address owner,
        address spender
    ) external view returns (uint256) {
        IERC20 erc20 = IERC20(erc20Contract);
        return erc20.allowance(owner, spender);
    }
}
