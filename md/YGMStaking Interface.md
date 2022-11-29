# **YGMStaking Interface**

```solidity
    // Total number of all staked YGM
    uint32 public stakeTotals;
    // The number of accounts in staking
    uint32 public accountTotals;

    // todo YGM token
    IERC721 public ygm;
    // Create_time
    uint64 public create_time;

    // todo usdt token
    IERC20 public usdt;
    // todo Time period
    uint64 public perPeriod;

    // Payment account
    address public paymentAccount;
    // Rate
    uint64 public earnRate = 50;

    // Staking Data
    mapping(uint256 => StakingData) stakingDatas;

    // List of account staking tokenId
    mapping(address => uint256[]) stakingTokenIds;

    // The amount of usdt shared by all users on a certain day
    mapping(uint256 => uint256) day_total_usdt;

    // The total amount of ygm staked on a certain day
    mapping(uint256 => uint256) day_total_stake;

    // The time a user staked
    mapping(address => uint256) stakeTime;

    // The income obtained by the user's previous stake
    mapping(address => uint256) stakeEarnAmount;

```



# 1. constructor

构造函数

```solidity
    constructor(
        address ygmAddress,
        address usdtAddress,
        address _paymentAccount,
        uint256 _create_time,
        uint256 _perPeriod
    )
```

- ygmAddress：YGM的合约地址
- usdtAddress：erc20 USDT的合约地址
- _paymentAccount：支付erc20 token的账户地址
- _create_time：质押活动的开始时间
- _perPeriod：设置每个时间段多少秒（10分钟 600s）

# 2. onlyOwner Set

## (1) start(_create_time, _period)

```solidity
    function start(
        uint256 _create_time,
        uint256 _period
    ) public onlyOwner returns (bool)
```

_create_time：设置质押活动的开始时间

_period：设置每个时间段多少秒（10分钟 600s）

注：在质押活动开始前，即无人参与质押是才可修改；若活动已开始并且有质押数据，再修改会产生数据冲突bug。

## (2) setDayAmount(_usdtAmount)

```solidity
    function setDayAmount(
        uint256 _usdtAmount
    ) external onlyOwner returns (bool) 	
```

_usdtAmount：owner设置当天所有质押者分红USDT的数量（添加）

## (3) setRate(_rate)

```solidity
    function setRate(uint256 _rate) external onlyOwner returns (bool) {
        require(_rate <= 100, "set rate error");
        earnRate = uint64(_rate);
        return true;
    }
```

_rate：设置用户提现的比率 （ _0 < rate < 100）

## (4) setYgm(_ygmAddress)

```solidity
    function setYgm(address _ygmAddress) external onlyOwner returns (bool) {
        ygm = IERC721(_ygmAddress);
        return true;
    }
```

## (5) setUsdt(_usdtAddress)

```solidity
    function setUsdt(address _usdtAddress) external onlyOwner returns (bool) {
        usdt = IERC20(_usdtAddress);
        return true;
    }
```

## (6) setPayAccount(_payAccount)

```solidity
    function setPayAccount(
        address _payAccount
    ) external onlyOwner returns (bool) {
        paymentAccount = _payAccount;
        return true;
    }
```

## (7) withdrawYgm(_account, _tokenId)

```solidity
    function withdrawYgm(
        address _account,
        uint256 _tokenId
    ) external onlyOwner returns (bool) 
```

当某用户不能取消质押时，owner可以强制将nft归还该所有者。
# 3. User 
## (1) stake(_tokenIds)

```solidity
    function stake(
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant updateEarn returns (bool)
```

_tokenIds：是一个uint256的数组，所质押NFT tokenId 的集合。

可质押一个或多个。

## (2) unStake(_tokenIds)

```solidity
    function unStake(
        uint256[] calldata _tokenIds
    ) external whenNotPaused nonReentrant updateEarn returns (bool) 
```

_tokenIds：是一个uint256的数组，所取消质押 NFT tokenId 的集合。

可取消质押一个或多个。

取消质押自动提现。

## (3) withdrawEarn()

```solidity
    function withdrawEarn()
        external
        whenNotPaused
        nonReentrant
        updateEarn
        returns (bool)
```

提现：提取质押所获得的USDT至账户。（需扣除相应的手续费）

只提现，不取消质押。

## (4) getReward(_account)

```solidity
    function getReward(address _account) public view returns (uint256)
```

查询_account用户质押NFT所获得的奖励（未提现时的）

## (5) getCurrentDay()

```solidity
    function getCurrentDay() external view returns (uint256)
```

获取当天的索引（或活动开始的是第几天）

## (6) getStakingAmount(_account)

```solidity
	function getStakingAmount(
        address _account
    ) external view returns (uint256) 
```

查询_account用户当前质押NFT 的数量

## (7) getStakingTokenIds(_account)

```solidity
    function getStakingTokenIds(
        address _account
    ) external view returns (uint256[] memory) 
```

查询_account用户当前质押NFT 的tokenId 列表(数组)

## (8) getDayTotalUsdt(_day)

```solidity
    function getDayTotalUsdt(uint256 _day) external view returns (uint256) {
        return day_total_usdt[_day];
    }
```

获取某日USDT的总量

## (9) getDayTotalStake(_day)

```solidity
    function getDayTotalStake(uint256 _day) external view returns (uint256) {
        return day_total_stake[_day];
    }
```

获取某日质押NFT的总量

## (10) getStakingData(_tokenId)

```solidity
    function getStakingData(
        uint256 _tokenId
    ) external view returns (address, bool) {
        return (stakingDatas[_tokenId].account, stakingDatas[_tokenId].state);
    }
```

获取 tokenId的质押数据，返回一个地址和布尔类型。若返回的布尔类型为true，则该NFT质押在合约中。