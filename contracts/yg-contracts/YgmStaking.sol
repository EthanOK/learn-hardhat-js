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
    IYGM ygm = IYGM(0x025d7D6df01074065B8Cfc9cb78456d417BBc6b7);
    // todo usdt token
    IERC20 usdt = IERC20(0x025d7D6df01074065B8Cfc9cb78456d417BBc6b7);

    uint64 public create_time;
    uint64 public day_timestamp = 1 days;
    uint64 public earnRate = 70;

    // Staking Data
    mapping(uint256 => StakingData) public stakingDatas;

    // account staking tokenId list
    mapping(address => uint256[]) internal stakingTokenIds;

    address public paymentAccount;
    mapping(uint256 => uint256) public day_total_usdt; //记录某天所有用户共分多少usdt

    mapping(uint256 => uint256) public day_total_stake; // 记录某天的ygm质押总量
    // // account staked and staking tokenId list
    // mapping(address => uint256[]) internal stakeTokenIds;
    // stake totals
    uint64 public stakeTotals; //记录所有质押YGM的总数
    uint64 public accountTotals; //记录当前参与质押的账户数量

    mapping(address => uint256) public stakeTime; //记录某用户质押的当前时间
    mapping(address => uint256) public stakeEarnAmount; //记录某用户质押的收益

    function getDays(uint256 _endtime, uint256 _startTime)
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
            uint256 _start = getDays(stakeTime[_sender], create_time);
            uint256 _end = getDays(block.timestamp, create_time);

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
        uint256 _days = getDays(block.timestamp, create_time);
        day_total_stake[_days] = stakeTotals;
    }
}

contract YgmStaking is Pausable, ReentrancyGuard, ERC721Holder, YgmStakingBase {
    // update stake earn
    modifier updateEarn() {
        address _sender = _msgSender();
        if (create_time < stakeTime[_sender]) {
            stakeEarnAmount[_sender] = getReward(_sender);
        }
        stakeTime[_sender] = block.timestamp;
        _;
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
            require(withdrawEarn(), "withdraw failure");
        }
        // sun stake Totals
        stakeTotals -= uint64(_number);
        _syncDayTotalStake();
        return true;
    }

    // withdraw Earn USDT
    // (YGM is still stake in the contract)
    function withdrawEarn()
        public
        whenNotPaused
        nonReentrant
        updateEarn
        returns (bool)
    {
        address sender = _msgSender();

        deduction(sender);
        uint256 earnAmount = stakeEarnAmount[sender];

        require(
            earnAmount > 0,
            "Insufficient balance available for withdrawal"
        );

        stakeEarnAmount[sender] = 0;
        usdt.transferFrom(paymentAccount, sender, earnAmount);

        emit WithdrawEarn(sender, earnAmount);
        return true;
    }

    function deduction(address _account) private {
        uint256 _days = getDays(block.timestamp, create_time);
        if (accountTotals > 0) {
            uint256 _earnAmount = stakeEarnAmount[_account];
            uint256 _realEarnAmount = (_earnAmount * earnRate) / 100;
            stakeEarnAmount[_account] = _realEarnAmount;
            day_total_usdt[_days] += (_earnAmount - _realEarnAmount);
        }
    }
}
