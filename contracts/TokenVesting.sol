// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract Colorbay is ERC20 {
    constructor() ERC20("YGToken", "YGT") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for Colorbay;

    event Released(uint256 amount);
    event Revoked();

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    bool public revocable;

    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _token Colorbay token which is being vested
     */
    function release(Colorbay _token) public {
        uint256 unreleased = releasableAmount(_token);

        require(unreleased > 0);

        released[address(_token)] = released[address(_token)].add(unreleased);

        _token.safeTransfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _token ERC20 token which is being vested
     */
    function revoke(Colorbay _token) public onlyOwner {
        require(revocable);
        require(!revoked[address(_token)]);

        uint256 balance = _token.balanceOf(address(this));

        uint256 unreleased = releasableAmount(_token);
        uint256 refund = balance.sub(unreleased);

        revoked[address(_token)] = true;

        _token.safeTransfer(owner(), refund);

        emit Revoked();
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param _token Colorbay token which is being vested
     */
    function releasableAmount(Colorbay _token) public view returns (uint256) {
        return vestedAmount(_token).sub(released[address(_token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _token ERC20 token which is being vested
     */
    function vestedAmount(Colorbay _token) public view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[address(_token)]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (
            block.timestamp >= start.add(duration) || revoked[address(_token)]
        ) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}
