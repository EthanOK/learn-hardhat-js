// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YGToken is ERC20, Ownable {
    // todo total
    uint256 private constant total = 1_000_000_000 * 1e18;
    // todo mint rate
    uint16[5] private mintRate = [10, 18, 52, 8, 12];
    // todo lock Time 180
    uint16[2] private lockTime = [180, 240];
    // todo release rate
    uint16 private releaseRate = 10;
    // todo time uint (seconds、minutes、hours、days)
    uint32 private timeUint = 1 days;
    // todo quarter
    uint32 private quarter = 90 * timeUint;
    // start time
    uint32 public startTime;
    // invest amount of every quarter
    uint256 private invest_amount_per;
    // team amount of every quarter
    uint256 private team_amount_per;

    uint256 private to_invest_balance;
    uint256 private to_team_balance;
    // invest team account
    address private invest_account;
    address private team_account;

    // todo _address
    /**
    [
        "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
        "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
        "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
        "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
        "0x17F6AD8Ef982297579C203069C1DbfFE4348c372"
    ]
    **/
    constructor(address[5] memory _address) ERC20("YGIO", "YGIO") {
        startTime = uint32(block.timestamp);

        invest_amount_per = (((total * mintRate[0]) / 100) * releaseRate) / 100;
        invest_account = _address[0];

        team_amount_per = (((total * mintRate[3]) / 100) * releaseRate) / 100;
        team_account = _address[3];
        // mint
        for (uint256 i = 0; i < _address.length; i++) {
            _mint(_address[i], (total * mintRate[i]) / 100);
        }
    }

    // set Start Time
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = uint32(_startTime);
    }

    // mint
    function mint(uint256 amount) external onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    // burn
    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != to, "from = to");
        if (from == invest_account) {
            // [0] invest
            uint256 available = to_invest_balance - balanceOf(from) + amount;
            require(
                available <= _getOpAmount(invest_amount_per, 0),
                "Insufficient number of operations available"
            );
        } else if (from == team_account) {
            //[1] team
            uint256 available = to_team_balance - balanceOf(from) + amount;
            require(
                available <= _getOpAmount(team_amount_per, 1),
                "Insufficient number of operations available"
            );
        }
        if (to == invest_account) {
            to_invest_balance += amount;
        } else if (to == team_account) {
            to_team_balance += amount;
        }
    }

    function _getOpAmount(uint256 _amount_per, uint256 _index)
        internal
        view
        returns (uint256)
    {
        uint256 time = block.timestamp - startTime;
        require(time > timeUint * lockTime[_index], "Balance Locking");
        // Calculate through the quarter when balance unlock
        uint256 count = (time - timeUint * lockTime[_index]) / quarter;
        return count * _amount_per;
    }

    // getOpAmount
    function getOpAmount(uint256 _index) external view returns (uint256) {
        require(_index == 0 || _index == 1, "index is wrong");
        if (_index == 0) {
            return _getOpAmount(invest_amount_per, 0);
        } else {
            return _getOpAmount(team_amount_per, 1);
        }
    }

    // get released transfer out amount
    function getReleasedAmount(uint256 _index) external view returns (uint256) {
        require(_index == 0 || _index == 1, "index is wrong");
        if (_index == 0) {
            return to_invest_balance - balanceOf(invest_account);
        } else {
            return to_team_balance - balanceOf(team_account);
        }
    }
}
