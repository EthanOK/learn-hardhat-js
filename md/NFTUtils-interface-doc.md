# NFT 工具合约

```solidity
contract NFTUtils is QueryNFTData, QueryERC20Data, WhiteList {}
```

**现有三个模块组成：**

- QueryNFTData
- QueryERC20Data
- WhiteList

## 一、NFT 查询接口(QueryNFTData)

### 1、tokenURI(address, uint256)

```solidity
function tokenURI(address contactAddr, uint256 tokenId)
	external
	view
	returns (string memory);
```

功能：查询 NFT 合约（contactAddr）中，tokenId 的 URI，返回 string 类型。

### 2、balanceOf(address, address)

```solidity
function balanceOf(address contactAddr, address account)
    external
    view
    returns (uint256);
```

功能：查询 NFT 合约（contactAddr）中，地址 account 持有的 NFT 数量，返回 uint256 类型。

### 3、ownerOf(address, uint256)

```solidity
function ownerOf(address contactAddr, uint256 tokenId)
    external
    view
    returns (address);
```

功能：查询 NFT 合约（contactAddr）中，tokenId 的持有者地址，返回 address 类型。

### 4、tokenIdIsAccount(address, uint256, address)

```solidity
function tokenIdIsAccount(
    address contactAddr,
    uint256 tokenId,
    address account
) external view returns (bool);
```

功能：查询 NFT 合约（contactAddr）中，tokenId 的持有者是否为 account，返回 bool 类型。

### 5、nameAndsymbol(address)

```solidity
function nameAndsymbol(address contactAddr)
    external
    view
    returns (string memory, string memory);
```

功能：查询 NFT 合约（contactAddr）的 name 和 symbol，返回元组（string, string）类型。

### 6、getApproved(address, uint256)

```solidity
function getApproved(address contactAddr, uint256 tokenId)
    external
    view
    returns (address);
```

功能：查询 NFT 合约（contactAddr）中，tokenId 的授权地址，返回 address 类型。

### 7、isApprovedForAll(address, address, address)

```solidity
function isApprovedForAll(
    address contactAddr,
    address owner,
    address operator
) external view returns (bool);
```

功能：查询 NFT 合约（contactAddr）中，owner 是否将持有 NFT 全部授权给 operator，返回 bool 类型。

### 8、totalSupply(address)

```solidity
function totalSupply(address contactAddr) external view returns (uint256);
```

功能：查询 NFT 合约（contactAddr）中 NFT 的总发行量（已铸造），返回 uint256 类型。

### 9、tokenOfOwnerByIndex(address, address, uint256)

```solidity
function tokenOfOwnerByIndex(
    address contactAddr,
    address owner,
    uint256 index
) external view returns (uint256);
```

功能：查询 NFT 合约（contactAddr）中指定 owner 和 index 的 tokenId，返回 uint256 类型。
配合 balanceOf()使用。（index < balanceOf(owner)）

### 10、tokenByIndex(address, uint256)

```solidity
function tokenByIndex(address contactAddr, uint256 index)
    external
    view
    returns (uint256);
```

功能：查询 NFT 合约（contactAddr）中指定 index 的 tokenId，返回 uint256 类型。（index < totalSupply()）

### 11、getSupportsInterface(address, bytes4)

```solidity
function getSupportsInterface(address contactAddr, bytes4 interfaceId)
	external
	view
	returns (bool)；
```

功能：查询 NFT 合约（contactAddr）中是否实现了某个接口，返回 bool 类型。可以用来判断此合约是否为 ERC721 合约。（此合约必须实现 IERC165 接口才可查询）

interfaceId：

IERC721：0x80ac58cd

IERC721Enumerable：0x780e9d63

IERC1155：0xd9b67a26

### 12、contractIsERC721(address)

```solidity
function contractIsERC721(address contactAddr)
	external
	view
	returns (bool);
```

功能：查询合约（contactAddr）是否为 ERC721 合约，返回 bool 类型。

### 13、getContractOwner(address)

```solidity
function getContractOwner(address contactAddr)
    external
    view
    returns (address);
```

功能：查询合约（contactAddr）的 Owner，返回 address 类型。

## 二、ERC20 查询接口(QueryERC20Data)

### 1、totalSupplyERC20(address)

```solidity
function totalSupplyERC20(address erc20Contract)
    external
    view
    returns (uint256);
```

功能：查询 REC20 合约（erc20Contract）token 的总发行量，返回 uint256 类型。

### 2、balanceOfERC20(address, address)

```solidity
function balanceOfERC20(address erc20Contract, address account)
    external
    view
    returns (uint256);
```

功能：查询 REC20 合约（erc20Contract）中 account 的账户余额，返回 uint256 类型。

### 3、allowanceERC20(address, address, address)

```solidity
function allowanceERC20(
    address erc20Contract,
    address owner,
    address spender
) external view returns (uint256);
```

功能：查询 REC20 合约（erc20Contract）中,owner 授权给 spender 的 token 数量，返回 uint256 类型。

### 4、nameSyDecERC20(address)

```solidity
function nameSyDecERC20(address erc20Contract)
	external
	view
	returns (
		string memory name,
		string memory symbol,
		uint8 decimals
	);
```

功能：查询 REC20 合约（erc20Contract）的 name、symbol、decimals，返回 元组（string, string, uint8） 类型。

# 三、白名单（WhiteList）

链下签名，链上校验

## 1、前端调用接口

### (1)、setContactData(address, address, address)

```solidity
function setContactData(
	address contactAddr,
	address verifier,
	address sourceAccount
) external onlyRole(OWNER_ROLE) returns (bool);
```

仅拥有 OWNER_ROLE 权限的 account 可调用 setContactDatas 函数。

功能：为地址为 contactAddr 的 erc20 合约或 erc721 合约设置验证签名的账户地址和分发 token 的源账户地址。

### (2)、claimERC20(address, address, uint256, uint256, uint256, bytes)

```solidity
function claimERC20(
	address contactAddr,
	address account,
	uint256 amount,
	uint256 total_account,
	uint256 timestamp,
	bytes calldata signature
) external whenNotPaused nonReentrant returns (bool);
```

功能：account 认领 amount 个 token（contactAddr），total_account 为 account 可认领的最大量，signature 为 contactAddr 对应验证者的对参数的签名。

### (3)、claimERC721(address, address, uint256, uint256, bytes)

```solidity
function claimERC721(
	address contactAddr,
	address account,
	uint256 tokenId,
	uint256 timestamp,
	bytes calldata signature
) external nonReentrant returns (bool);
```

功能：account 认领 nft（contactAddr）合约的 tokenId，signature 为 contactAddr 对应验证者的对参数的签名。

### (4)、getContractData(address)

```solidity
function getContractData(address contactAddr)
	external
	view
	returns (address, address);
```

功能：获取 erc20 或 erc721 合约地址（contactAddr）所对应的验证签名的账户地址和分发 token 的源账户地址。

### (5)、getSumClaimedERC20(address, address)

```solidity
function getSumClaimedERC20(address contactAddr, address account)
	external
	view
	returns (uint256);
```

功能：获取账户 account 使用我们的 nftutils 合约 认领了多少个合约 erc20 代币（代币的合约地址为 contactAddr）

## 2、后台监控事件 event

### (1)、SetContractDatas

```solidity
event SetContractData(
	address indexed contactAddr,
	address indexed verifier,
	address indexed sourceAccount
);
```

### (2)、ClaimedERC20

```solidity
event ClaimedERC20(
	address indexed contactAddr,
	address indexed account,
	uint256 indexed amount
);
```

### (3)、ClaimedERC721

```solidity
event ClaimedERC721(
	address indexed contactAddr,
	address indexed account,
	uint256 indexed tokenId
);
```

# #待添加功能
