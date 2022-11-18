// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// WhiteList: Off-chain signature on-chain verification
abstract contract WhiteList is Pausable, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    struct ContractData {
        // Whitelist verifier
        address verifier;
        // Whitelist Source Account
        address sourceAccount;
    }
    // contactAddr => ContractData
    mapping(address => ContractData) private contractDatas;
    // erc20 Sum of Claim
    mapping(address => mapping(address => uint256)) public erc20_sumClaim;

    event SetContractData(
        address indexed contactAddr,
        address indexed verifier,
        address indexed sourceAccount
    );
    event ClaimedERC20(
        address indexed contactAddr,
        address indexed account,
        uint256 indexed amount
    );
    event ClaimedERC721(
        address indexed contactAddr,
        address indexed account,
        uint256 indexed tokenId
    );

    function setContactData(
        address contactAddr,
        address verifier,
        address sourceAccount
    ) external onlyOwner returns (bool) {
        contractDatas[contactAddr].verifier = verifier;
        contractDatas[contactAddr].sourceAccount = sourceAccount;
        emit SetContractData(contactAddr, verifier, sourceAccount);
        return true;
    }

    function claimERC20(
        address contactAddr,
        address account,
        uint256 amount,
        uint256 total_account,
        uint256 timestamp,
        bytes calldata signature
    ) external whenNotPaused nonReentrant returns (bool) {
        // expirationTime  180s
        require(
            timestamp + 180 >= block.timestamp && block.timestamp >= timestamp,
            "expiration time"
        );

        require(
            amount > 0 &&
                amount + erc20_sumClaim[contactAddr][account] <= total_account,
            "Exceed Claim Total"
        );

        // Verify account claimed
        bytes32 hashdata = keccak256(
            abi.encodePacked(
                contactAddr,
                account,
                amount,
                total_account,
                timestamp
            )
        ).toEthSignedMessageHash();
        _verify(contactAddr, hashdata, signature);

        // add erc20 sum Claim
        erc20_sumClaim[contactAddr][account] += amount;

        // Transfer condition: sourceAccount approve this.addres
        IERC20Metadata erc20 = IERC20Metadata(contactAddr);
        erc20.transferFrom(
            contractDatas[contactAddr].sourceAccount,
            account,
            amount
        );
        emit ClaimedERC20(contactAddr, account, amount);
        return true;
    }

    function claimERC721(
        address contactAddr,
        address account,
        uint256 tokenId,
        uint256 timestamp,
        bytes calldata signature
    ) external nonReentrant returns (bool) {
        // expirationTime  180s
        require(
            timestamp + 180 >= block.timestamp && block.timestamp >= timestamp,
            "expiration time"
        );

        // Verify account claimed
        bytes32 hashdata = keccak256(
            abi.encodePacked(contactAddr, account, tokenId, timestamp)
        ).toEthSignedMessageHash();
        _verify(contactAddr, hashdata, signature);

        IERC721Metadata erc721 = IERC721Metadata(contactAddr);

        // safeTransferFrom condition: sourceAccount setApprovalForAll this.address
        erc721.safeTransferFrom(
            contractDatas[contactAddr].sourceAccount,
            account,
            tokenId
        );

        emit ClaimedERC721(contactAddr, account, tokenId);
        return true;
    }

    function getContractData(address contactAddr)
        external
        view
        returns (address, address)
    {
        return (
            contractDatas[contactAddr].verifier,
            contractDatas[contactAddr].sourceAccount
        );
    }

    function getSumClaimedERC20(address contactAddr, address account)
        external
        view
        returns (uint256)
    {
        return erc20_sumClaim[contactAddr][account];
    }

    function _verify(
        address contactAddr,
        bytes32 hashdata,
        bytes calldata signature
    ) internal view returns (bool) {
        require(
            contractDatas[contactAddr].verifier == hashdata.recover(signature),
            "Invalid signature"
        );
        return true;
    }
}

abstract contract QueryNFTData {
    // get contract's owner [return address or revert]
    function getContractOwner(address contactAddr)
        external
        view
        returns (address)
    {
        try Ownable(contactAddr).owner() returns (address _owner) {
            return _owner;
        } catch {
            revert("external call failed");
        }
    }

    // contract Is erc721
    function contractIsERC721(address contactAddr)
        external
        view
        returns (bool)
    {
        try
            IERC165(contactAddr).supportsInterface(type(IERC721).interfaceId)
        returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function getSupportsInterface(address contactAddr, bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        try IERC165(contactAddr).supportsInterface(interfaceId) returns (
            bool result
        ) {
            return result;
        } catch {
            return false;
        }
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

    // totalSupply [return uint256 or revert]
    function totalSupply(address contactAddr) external view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        // function totalSupply() exist?
        try erc721.totalSupply() returns (uint256 result) {
            return result;
        } catch {
            revert("external call failed");
        }
    }

    // tokenOfOwnerByIndex [return uint256 or revert]
    function tokenOfOwnerByIndex(
        address contactAddr,
        address owner,
        uint256 index
    ) external view returns (uint256) {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        try erc721.tokenOfOwnerByIndex(owner, index) returns (uint256 result) {
            return result;
        } catch {
            revert("external call failed");
        }
    }

    // tokenByIndex [return uint256 or revert]
    function tokenByIndex(address contactAddr, uint256 index)
        external
        view
        returns (uint256)
    {
        IERC721Enumerable erc721 = IERC721Enumerable(contactAddr);
        // function tokenByIndex() exist?
        try erc721.tokenByIndex(index) returns (uint256 result) {
            return result;
        } catch {
            revert("external call failed");
        }
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

contract NFTUtils is QueryNFTData, QueryERC20Data, WhiteList {
    constructor() {}
}
