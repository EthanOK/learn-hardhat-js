// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract HivePledge is Ownable {
    using SafeMath for uint256;

    uint public create_time;
    uint public day_timestamp = 1 days;

    IERC20 private lp;

    IERC20 private rst;

    IERC20 private tcs;

    mapping(address => uint) addressTotalPledgeAmount;

    uint public totalPledgeAmount;
    uint public totalPledgeAddresses;

    uint public havestRate = 49;

    mapping(uint => uint) public day_total_rst;
    mapping(uint => uint) public day_total_tcs;

    mapping(uint => uint) public day_total_pledge;

    mapping(address => uint) public harvestRstTime;
    mapping(address => uint) public harvestRstAmount;

    mapping(address => uint) public harvestTcsTime;
    mapping(address => uint) public harvestTcsAmount;

    address public rstAddress;
    address public tcsAddress;

    event Pledge(address indexed pledgeAddress, uint256 value);
    event Release(address indexed releaseAddress, uint256 value);
    event HarvestRst(address indexed harvestAddress, uint256 value);
    event HarvestTcs(address indexed harvestAddress, uint256 value);

    constructor(
        address _lp,
        address _rst,
        address _tcs,
        address _rstAddress,
        address _tcsAddress
    ) {
        lp = IERC20(_lp);
        rst = IERC20(_rst);
        tcs = IERC20(_tcs);
        rstAddress = _rstAddress;
        tcsAddress = _tcsAddress;
    }

    function getDays(uint _endtime, uint _startTime)
        public
        view
        returns (uint)
    {
        return _endtime.sub(_startTime).div(day_timestamp);
    }

    function getDayTotalPledge(uint _day) external view returns (uint) {
        return day_total_pledge[_day];
    }

    function getAddressPledgeTotal(address _address)
        external
        view
        returns (uint)
    {
        return addressTotalPledgeAmount[_address];
    }

    function getRewardRst(address _sender) public view returns (uint) {
        if (0 < harvestRstTime[_sender]) {
            uint _start = getDays(harvestRstTime[_sender], create_time);
            uint _end = getDays(block.timestamp, create_time);

            uint _totalHarvest = 0;

            for (uint i = _start; i < _end; i++) {
                if (0 < day_total_pledge[i]) {
                    uint _harvest = day_total_rst[i]
                        .mul(addressTotalPledgeAmount[_sender])
                        .div(day_total_pledge[i]);
                    _totalHarvest = _totalHarvest.add(_harvest);
                }
            }

            return _totalHarvest.add(harvestRstAmount[_sender]);
        } else {
            return 0;
        }
    }

    function getRewardTcs(address _sender) public view returns (uint) {
        if (0 < harvestTcsTime[_sender]) {
            uint _start = getDays(harvestTcsTime[_sender], create_time);
            uint _end = getDays(block.timestamp, create_time);

            uint _totalHarvest = 0;

            for (uint i = _start; i < _end; i++) {
                if (0 < day_total_pledge[i]) {
                    uint _harvest = day_total_tcs[i]
                        .mul(addressTotalPledgeAmount[_sender])
                        .div(day_total_pledge[i]);
                    _totalHarvest = _totalHarvest.add(_harvest);
                }
            }

            return _totalHarvest.add(harvestTcsAmount[_sender]);
        } else {
            return 0;
        }
    }

    function harvestRst() public updateHarvest returns (bool) {
        address _sender = _msgSender();

        uint _days = getDays(block.timestamp, create_time);
        deductionRst(_sender, _days);

        uint harvestAmount = harvestRstAmount[_sender];

        require(harvestAmount > 0, "No balance for harvest");

        rst.transferFrom(rstAddress, _sender, harvestAmount);

        harvestRstAmount[_sender] = 0;

        emit HarvestRst(_sender, harvestAmount);

        return true;
    }

    function harvestTcs() public updateHarvest returns (bool) {
        address _sender = _msgSender();

        uint _days = getDays(block.timestamp, create_time);
        deductionTcs(_sender, _days);

        uint harvestAmount = harvestTcsAmount[_sender];

        require(harvestAmount > 0, "No balance for harvest");

        tcs.transferFrom(tcsAddress, _sender, harvestAmount);

        harvestTcsAmount[_sender] = 0;

        emit HarvestTcs(_sender, harvestAmount);

        return true;
    }

    function pledge(uint _pledgeAmount) external updateHarvest returns (bool) {
        address sender = _msgSender();

        require(0 < _pledgeAmount, "PledgeAmount:  less than zero ");

        lp.transferFrom(sender, address(this), _pledgeAmount);

        addAddressTotalPledgeAmount(sender, _pledgeAmount);
        addTotalPledgeAmount(_pledgeAmount);

        emit Pledge(sender, _pledgeAmount);

        return true;
    }

    function release() external updateHarvest returns (bool) {
        address _sender = _msgSender();

        if (0 < harvestRstAmount[_sender]) {
            harvestRst();
        }

        if (0 < harvestTcsAmount[_sender]) {
            harvestTcs();
        }

        uint _pledage_amount = addressTotalPledgeAmount[_sender];

        require(0 < _pledage_amount, "Pledage amount is zero");

        lp.transfer(_sender, _pledage_amount);

        subAddressTotalPledgeAmount(_sender, _pledage_amount);
        subTotalPledgeAmount(_pledage_amount);

        emit Release(_sender, _pledage_amount);

        return true;
    }

    function setDayAmount(uint _rstAmount, uint _tcsAmount)
        external
        onlyOwner
        returns (bool)
    {
        uint _days = getDays(block.timestamp, create_time);

        day_total_rst[_days] = day_total_rst[_days].add(_rstAmount);
        day_total_tcs[_days] = day_total_tcs[_days].add(_tcsAmount);

        _syncDayTotalPledge();

        return true;
    }

    function start(uint _timestamp, uint _day_timestamp)
        public
        onlyOwner
        returns (bool)
    {
        if (0 != _timestamp) {
            create_time = _timestamp;
        }

        if (0 != _day_timestamp) {
            day_timestamp = _day_timestamp;
        }

        return true;
    }

    function withDrawLp(address _address, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        lp.transfer(_address, _amount);
        return true;
    }

    function setRate(uint _rate) external onlyOwner returns (bool) {
        havestRate = _rate;
        return true;
    }

    function setLp(address _lpAddress) external onlyOwner returns (bool) {
        lp = IERC20(_lpAddress);
        return true;
    }

    function setRst(address _rstAddress) external onlyOwner returns (bool) {
        rst = IERC20(_rstAddress);
        return true;
    }

    function setTcs(address _tcsAddress) external onlyOwner returns (bool) {
        tcs = IERC20(_tcsAddress);
        return true;
    }

    function setRstWithDraw(address _address)
        external
        onlyOwner
        returns (bool)
    {
        rstAddress = _address;
        return true;
    }

    function setTcsWithDraw(address _address)
        external
        onlyOwner
        returns (bool)
    {
        tcsAddress = _address;
        return true;
    }

    function deductionReward(address _sender) private {
        uint _days = getDays(block.timestamp, create_time);
        deductionRst(_sender, _days);
        deductionTcs(_sender, _days);
    }

    function deductionRst(address _pledgeAddress, uint _datys) private {
        if (1 < totalPledgeAddresses) {
            uint _harvestRstAmount = harvestRstAmount[_pledgeAddress];
            uint _realHavestAmount = _harvestRstAmount.mul(havestRate).div(100);
            harvestRstAmount[_pledgeAddress] = _realHavestAmount;
            day_total_rst[_datys] = day_total_rst[_datys].add(
                _harvestRstAmount.sub(_realHavestAmount)
            );
        }
    }

    function deductionTcs(address _pledgeAddress, uint _datys) private {
        if (1 < totalPledgeAddresses) {
            uint _harvestTcsAmount = harvestTcsAmount[_pledgeAddress];
            uint _realHavestAmount = _harvestTcsAmount.mul(havestRate).div(100);
            harvestTcsAmount[_pledgeAddress] = _realHavestAmount;
            day_total_tcs[_datys] = day_total_tcs[_datys].add(
                _harvestTcsAmount.sub(_realHavestAmount)
            );
        }
    }

    function addAddressTotalPledgeAmount(
        address _pledgeAddress,
        uint _pledgeAmount
    ) private {
        if (0 == addressTotalPledgeAmount[_pledgeAddress]) {
            totalPledgeAddresses = totalPledgeAddresses.add(1);
        }

        addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[
            _pledgeAddress
        ].add(_pledgeAmount);
    }

    function addTotalPledgeAmount(uint _pledgeAmount) private {
        totalPledgeAmount = totalPledgeAmount.add(_pledgeAmount);
        _syncDayTotalPledge();
    }

    function subAddressTotalPledgeAmount(
        address _pledgeAddress,
        uint _pledgeAmount
    ) private {
        addressTotalPledgeAmount[_pledgeAddress] = addressTotalPledgeAmount[
            _pledgeAddress
        ].sub(_pledgeAmount);
        if (0 >= addressTotalPledgeAmount[_pledgeAddress]) {
            totalPledgeAddresses = totalPledgeAddresses.sub(1);
        }
    }

    function subTotalPledgeAmount(uint _pledgeAmount) private {
        totalPledgeAmount = totalPledgeAmount.sub(_pledgeAmount);
        _syncDayTotalPledge();
    }

    function _syncDayTotalPledge() private {
        uint _days = getDays(block.timestamp, create_time);
        day_total_pledge[_days] = totalPledgeAmount;
    }

    modifier updateHarvest() {
        address _sender = _msgSender();

        if (create_time < harvestRstTime[_sender]) {
            harvestRstAmount[_sender] = getRewardRst(_sender);
        }
        harvestRstTime[_sender] = block.timestamp;

        if (create_time < harvestTcsTime[_sender]) {
            harvestTcsAmount[_sender] = getRewardTcs(_sender);
        }
        harvestTcsTime[_sender] = block.timestamp;

        _;
    }
}
