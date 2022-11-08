// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract WhiteList is ReentrancyGuard, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    struct Data {
        // Whitelist MerkleRoot
        bytes32 merkleRoot;
        // Whitelist Source Account
        address sourceAccount;
    }
    // white list merkle Roots
    // contactAddr => issueId => Date
    mapping(address => mapping(uint256 => Data)) whiteLists;

    // account Claimed State
    // keccak256(contactAddr,issueId,account) => state
    mapping(bytes32 => bool) accountStates;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    event SetWhiteLists(
        address indexed contactAddr,
        uint256 indexed issueId,
        bytes32 indexed merkleRoot,
        address sourceAccount
    );
    event ClaimedERC20(
        address indexed contactAddr,
        uint256 indexed issueId,
        address indexed account,
        uint256 amount
    );
    event ClaimedERC721(
        address indexed contactAddr,
        uint256 indexed issueId,
        address indexed account,
        uint256 tokenId
    );

    function setWhiteLists(
        address contactAddr,
        uint256 issueId,
        bytes32 merkleRoot,
        address sourceAccount
    ) external onlyRole(OWNER_ROLE) returns (bool) {
        whiteLists[contactAddr][issueId].merkleRoot = merkleRoot;
        whiteLists[contactAddr][issueId].sourceAccount = sourceAccount;
        emit SetWhiteLists(contactAddr, issueId, merkleRoot, sourceAccount);
        return true;
    }

    function claimERC20(
        address contactAddr,
        uint256 issueId,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant returns (bool) {
        // Verify account claimed State
        bytes32 stateId = keccak256(
            abi.encodePacked(contactAddr, issueId, account)
        );
        require(!accountStates[stateId], "Account has been claimed");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(account, amount));

        bytes32 merkleRoot = whiteLists[contactAddr][issueId].merkleRoot;
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        IERC20Metadata erc20 = IERC20Metadata(contactAddr);
        address source = whiteLists[contactAddr][issueId].sourceAccount;

        // Necessary condition: sourceAccount approve this.address
        erc20.transferFrom(source, account, amount);
        // Change state
        accountStates[stateId] = true;

        emit ClaimedERC20(contactAddr, issueId, account, amount);
        return true;
    }

    function claimERC721(
        address contactAddr,
        uint256 issueId,
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external nonReentrant returns (bool) {
        // Verify account claimed State
        bytes32 stateId = keccak256(
            abi.encodePacked(contactAddr, issueId, account)
        );
        require(!accountStates[stateId], "Account has been claimed");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(account, tokenId));

        bytes32 merkleRoot = whiteLists[contactAddr][issueId].merkleRoot;
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        IERC721Metadata erc721 = IERC721Metadata(contactAddr);
        address source = whiteLists[contactAddr][issueId].sourceAccount;

        // Necessary condition: sourceAccount setApprovalForAll this.address
        erc721.safeTransferFrom(source, account, tokenId);
        // Change state
        accountStates[stateId] = true;

        emit ClaimedERC721(contactAddr, issueId, account, tokenId);
        return true;
    }

    function getAccountClaimedState(
        address contactAddr,
        uint256 issueId,
        address account
    ) external view returns (bool) {
        bytes32 stateId = keccak256(
            abi.encodePacked(contactAddr, issueId, account)
        );
        return accountStates[stateId];
    }
}

abstract contract QueryNFTData {
    function supportsInterface(address contactAddr, bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        IERC165 erc165 = IERC165(contactAddr);
        return erc165.supportsInterface(interfaceId);
    }

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

    // totalSupply [return uint256 or error]
    function totalSupply(address contactAddr) external view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        // function totalSupply() exist?
        return erc721.totalSupply();
    }

    // tokenOfOwnerByIndex [return uint256 or error]
    function tokenOfOwnerByIndex(
        address contactAddr,
        address owner,
        uint256 index
    ) external view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        // function tokenOfOwnerByIndex() exist?
        return erc721.tokenOfOwnerByIndex(owner, index);
    }

    // tokenByIndex [return uint256 or error]
    function tokenByIndex(address contactAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        // function tokenByIndex() exist?
        return erc721.tokenByIndex(index);
    }
}

abstract contract QueryERC20Data {
    // ERC20 totalSupply
    function totalSupplyERC20(address erc20Contract)
        external
        view
        returns (uint256)
    {
        IERC20Metadata erc20 = IERC20Metadata(erc20Contract);
        return erc20.totalSupply();
    }

    // ERC20 balanceOf
    function balanceOfERC20(address erc20Contract, address account)
        external
        view
        returns (uint256)
    {
        IERC20Metadata erc20 = IERC20Metadata(erc20Contract);
        return erc20.balanceOf(account);
    }

    // ERC20 allowance
    function allowanceERC20(
        address erc20Contract,
        address owner,
        address spender
    ) external view returns (uint256) {
        IERC20Metadata erc20 = IERC20Metadata(erc20Contract);
        return erc20.allowance(owner, spender);
    }

    // ERC20 name symbol decimals
    function nameSyDecERC20(address erc20Contract)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        )
    {
        IERC20Metadata erc20 = IERC20Metadata(erc20Contract);
        return (erc20.name(), erc20.symbol(), erc20.decimals());
    }
}

contract NFTUtils is QueryNFTData, QueryERC20Data, WhiteList {}
