// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// YGM interface
interface IYGM {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

abstract contract YgmStakingBase is Pausable, Ownable {
    // staking data event
    event Stake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    event UnStake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 timestamp
    );
    event WithdrawEarn(address indexed account, uint256 amount);

    // staking data
    struct StakingData {
        address account;
        bool state;
    }

    // todo YGM token
    IYGM immutable ygm;
    // todo usdt token
    IERC20 immutable usdt;

    uint64 public create_time;
    uint64 public day_timestamp = 1 days;
    uint64 public earnRate = 70;

    // stake totals
    uint64 public stakeTotals; //记录所有质押YGM的总数
    uint64 public accountTotals; //记录当前参与质押的账户数量

    address public paymentAccount;
    // Staking Data
    mapping(uint256 => StakingData) public stakingDatas;

    // account staking tokenId list
    mapping(address => uint256[]) internal stakingTokenIds;

    mapping(uint256 => uint256) public day_total_usdt; //记录某天所有用户共分多少usdt

    // the total amount of ygm staked on a certain day
    mapping(uint256 => uint256) public day_total_stake;

    mapping(address => uint256) public stakeTime; //记录某用户质押的当前时间
    mapping(address => uint256) public stakeEarnAmount; //记录某用户质押的收益

    constructor(address ygm_address, address usdt_address) {
        ygm = IYGM(ygm_address);
        usdt = IERC20(usdt_address);
    }

    function getDayTotalStake(uint _day) external view returns (uint) {
        return day_total_stake[_day];
    }

    // get account staking tokenId list
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
        // calculate the withdrawal ratio
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

    // update stake earn
    modifier updateEarn() {
        address _sender = _msgSender();
        if (create_time < stakeTime[_sender]) {
            stakeEarnAmount[_sender] = getReward(_sender);
        }
        stakeTime[_sender] = block.timestamp;
        _;
    }
}

contract YgmStaking is Pausable, ReentrancyGuard, ERC721Holder, YgmStakingBase {
    constructor(
        address ygm_address,
        address usdt_address,
        address payment
    ) YgmStakingBase(ygm_address, usdt_address) {
        paymentAccount = payment;
    }

    // batch stake YGM
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

            //_tokenId add in stakingTokenIds[account] list
            stakingTokenIds[msg.sender].push(_tokenId);

            emit Stake(_sender, _tokenId, block.timestamp);
        }

        // add stake Totals
        stakeTotals += uint64(_number);
        _syncDayTotalStake();
        return true;
    }

    // batch stake YGM
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
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == _sender, "invalid account");
            require(_data.state, "invalid stake state");

            // safeTransferFrom
            ygm.safeTransferFrom(address(this), _data.account, _tokenId);

            // delete tokenId
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

            // sub account total
            if (stakingTokenIds[_sender].length == 0) {
                accountTotals -= 1;
            }
            // reset data
            _data.state = false;

            emit UnStake(_sender, _tokenId, block.timestamp);
        }
        if (stakeEarnAmount[_sender] > 0) {
            uint256 amount = _withdrawEarn(_sender);
            emit WithdrawEarn(_sender, amount);
        }
        // sun stake Totals
        stakeTotals -= uint64(_number);
        _syncDayTotalStake();
        return true;
    }

    // withdraw Earn USDT
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
        emit WithdrawEarn(sender, amount);
        return true;
    }
}
