// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract YgmStakingBase is Ownable, Pausable {
    // Stake event
    event Stake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    // UnStake event
    event UnStake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    // Withdraw Earn event
    event WithdrawEarn(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    // Staking data
    struct StakingData {
        address account;
        bool state;
    }

    // Total number of all staked YGM
    uint32 public stakeTotals;
    // The number of accounts in staking
    uint32 public accountTotals;

    // todo YGM token
    IERC721 ygm;
    // Create_time
    uint64 public create_time;

    // todo usdt token
    IERC20 usdt;
    // Time period
    uint64 public day_timestamp = 1 days;

    // Payment account
    address public paymentAccount;
    // Rate
    uint64 public earnRate = 70;

    // Staking Data
    mapping(uint256 => StakingData) public stakingDatas;

    // List of account staking tokenId
    mapping(address => uint256[]) stakingTokenIds;

    // The amount of usdt shared by all users on a certain day
    mapping(uint256 => uint256) public day_total_usdt;

    // The total amount of ygm staked on a certain day
    mapping(uint256 => uint256) public day_total_stake;

    // The time a user staked
    mapping(address => uint256) public stakeTime;

    // The income of a user's stake
    mapping(address => uint256) public stakeEarnAmount;

    // Set the amount of usdt allocated on a certain day (onlyOwner)
    function setDayAmount(uint _usdtAmount) external onlyOwner returns (bool) {
        uint _days = getDays(create_time, block.timestamp);
        day_total_usdt[_days] += _usdtAmount;
        return true;
    }

    // Set create_time and day_timestamp (onlyOwner)
    function start(uint _create_time, uint _day_timestamp)
        external
        onlyOwner
        returns (bool)
    {
        require(_create_time > 0 && _day_timestamp > 0, "set time error");
        create_time = uint64(_create_time);
        day_timestamp = uint64(_day_timestamp);
        return true;
    }

    // Set eran rate (onlyOwner)
    function setRate(uint _rate) external onlyOwner returns (bool) {
        require(_rate <= 100, "set rate error");
        earnRate = uint64(_rate);
        return true;
    }

    // Set YGM contract address (onlyOwner)
    function setYgm(address _ygmAddress) external onlyOwner returns (bool) {
        ygm = IERC721(_ygmAddress);
        return true;
    }

    // Set usdt contract address (onlyOwner)
    function setUsdt(address _usdtAddress) external onlyOwner returns (bool) {
        usdt = IERC20(_usdtAddress);
        return true;
    }

    // Set payment account address (onlyOwner)
    function setPayAccount(address _payAccount)
        external
        onlyOwner
        returns (bool)
    {
        paymentAccount = _payAccount;
        return true;
    }

    // Withdraw YGm (onlyOwner)
    function withdrawYgm(address _account, uint _tokenId)
        external
        onlyOwner
        returns (bool)
    {
        StakingData memory _data = stakingDatas[_tokenId];
        require(_data.state == true, "tokenId isn't staked");
        require(_data.account == _account, "tokenId doesn't belong to account");
        ygm.safeTransferFrom(address(this), _account, _tokenId);
        delete stakingDatas[_tokenId];
        return true;
    }

    // Get the total amount of staking on a certain day
    function getDayTotalStake(uint _day) external view returns (uint) {
        return day_total_stake[_day];
    }

    // Get account staking tokenId list
    function getStakingTokenIds(address _account)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokenIds = stakingTokenIds[_account];
        return _tokenIds;
    }

    function getDays(uint256 _startTime, uint256 _endtime)
        public
        view
        returns (uint256)
    {
        uint256 _days = (_endtime - _startTime) / day_timestamp;
        return _days;
    }

    function getReward(address _sender) public view returns (uint256) {
        if (0 < stakeTime[_sender]) {
            uint256 account_staking_amount = stakingTokenIds[_sender].length;
            require(account_staking_amount > 0, "Account doesn't stake");
            uint256 _start = getDays(create_time, stakeTime[_sender]);
            uint256 _end = getDays(create_time, block.timestamp);

            uint256 _totalEarn = 0;

            for (uint256 i = _start; i < _end; i++) {
                if (0 < day_total_stake[i]) {
                    uint256 _earn = (day_total_usdt[i] *
                        account_staking_amount) / day_total_stake[i];
                    _totalEarn += _earn;
                }
            }

            return _totalEarn + stakeEarnAmount[_sender];
        } else {
            return 0;
        }
    }

    function _syncDayTotalStake() internal {
        uint256 _days = getDays(create_time, block.timestamp);
        day_total_stake[_days] = stakeTotals;
    }

    function _withdrawEarn(address _account) internal returns (uint256) {
        // Calculate the withdrawal ratio
        uint256 _realEarnAmount;
        uint256 _days = getDays(create_time, block.timestamp);
        if (accountTotals > 0) {
            uint256 _earnAmount = stakeEarnAmount[_account];
            _realEarnAmount = (_earnAmount * earnRate) / 100;
            day_total_usdt[_days] += (_earnAmount - _realEarnAmount);
        }

        require(
            _realEarnAmount > 0,
            "Insufficient balance available for withdrawal"
        );
        stakeEarnAmount[_account] = 0;
        usdt.transferFrom(paymentAccount, _account, _realEarnAmount);
        return _realEarnAmount;
    }

    // Update stake earn
    modifier updateEarn() {
        address _sender = _msgSender();
        if (create_time < stakeTime[_sender]) {
            stakeEarnAmount[_sender] = getReward(_sender);
        }
        stakeTime[_sender] = block.timestamp;
        _;
    }
}

contract YgmStaking is ReentrancyGuard, ERC721Holder, YgmStakingBase {
    constructor(
        address ygm_address,
        address usdt_address,
        address payment
    ) {
        ygm = IERC721(ygm_address);
        usdt = IERC20(usdt_address);
        paymentAccount = payment;
    }

    // Batch stake YGM
    function stake(uint256[] calldata _tokenIds)
        external
        whenNotPaused
        nonReentrant
        updateEarn
        returns (bool)
    {
        address _sender = _msgSender();
        uint256 _number = _tokenIds.length;
        require(_number > 0, "invalid tokenIds");

        for (uint256 i = 0; i < _number; i++) {
            require(_tokenIds[i] > 0, "invalid tokenId");
            require(!stakingDatas[_tokenIds[i]].state, "invalid stake state");
            require(ygm.ownerOf(_tokenIds[i]) == _sender, "invalid owner");
        }

        if (stakingTokenIds[_sender].length == 0) {
            accountTotals += 1;
        }

        for (uint256 i = 0; i < _number; i++) {
            uint256 _tokenId = _tokenIds[i];
            ygm.safeTransferFrom(msg.sender, address(this), _tokenId);

            StakingData storage _data = stakingDatas[_tokenId];
            _data.account = _sender;
            _data.state = true;

            // Add _tokenId in stakingTokenIds[account] list
            stakingTokenIds[msg.sender].push(_tokenId);

            emit Stake(_sender, _tokenId, block.timestamp);
        }

        // Add stake Totals
        stakeTotals += uint32(_number);
        _syncDayTotalStake();
        return true;
    }

    // Batch stake YGM
    function unStake(uint256[] calldata _tokenIds)
        external
        whenNotPaused
        nonReentrant
        updateEarn
        returns (bool)
    {
        address _sender = _msgSender();
        uint256 _number = _tokenIds.length;
        require(_number > 0, "invalid tokenIds");
        for (uint256 i = 0; i < _number; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData memory _data = stakingDatas[_tokenId];
            require(_data.account == _sender, "invalid account");
            require(_data.state, "invalid stake state");

            // SafeTransferFrom
            ygm.safeTransferFrom(address(this), _data.account, _tokenId);

            // Delete tokenId
            uint256 _len = stakingTokenIds[_sender].length;
            for (uint256 j = 0; j < _len; j++) {
                if (stakingTokenIds[_sender][j] == _tokenId) {
                    stakingTokenIds[_sender][j] = stakingTokenIds[_sender][
                        _len - 1
                    ];
                    stakingTokenIds[msg.sender].pop();
                    break;
                }
            }

            // Sub account total
            if (stakingTokenIds[_sender].length == 0) {
                accountTotals -= 1;
            }
            // Reset data
            delete stakingDatas[_tokenId];

            emit UnStake(_sender, _tokenId, block.timestamp);
        }
        if (stakeEarnAmount[_sender] > 0) {
            uint256 amount = _withdrawEarn(_sender);
            emit WithdrawEarn(_sender, amount, block.timestamp);
        }
        // Sub stake Totals
        stakeTotals -= uint32(_number);
        _syncDayTotalStake();
        return true;
    }

    // Withdraw Earn USDT
    // (YGM is still stake in the contract)
    function withdrawEarn()
        external
        whenNotPaused
        nonReentrant
        updateEarn
        returns (bool)
    {
        address sender = _msgSender();
        require(stakeEarnAmount[sender] > 0, "Insufficient balance");
        uint256 amount = _withdrawEarn(sender);
        emit WithdrawEarn(sender, amount, block.timestamp);
        return true;
    }
}
