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
    // sign expiration time
    uint256 internal constant EXP_TIME = 180;

    // staking data event
    event Stake(
        address indexed account,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime
    );
    // staking data
    struct StakingData {
        address account;
        uint64 startTime;
        uint64 endTime;
    }
    // todo YGM token
    IYGM ygm = IYGM(0x025d7D6df01074065B8Cfc9cb78456d417BBc6b7);
    // Staking Data
    mapping(uint256 => StakingData) public stakingDatas;
    // tokenId staked state
    mapping(uint256 => bool) public stakedState;
    // account staking tokenId list
    mapping(address => uint256[]) internal stakingTokenIds;
    // account staked and staking tokenId list
    mapping(address => uint256[]) internal stakeTokenIds;
    // stake totals
    mapping(bytes => uint256) public stakeTotals;
}

contract YgmStaking is Pausable, ReentrancyGuard, ERC721Holder, YgmStakingBase {
    function stake(
        uint256[] calldata _tokenIds,
        uint256 timestamp,
        bytes calldata signature
    ) external whenNotPaused nonReentrant returns (bool) {
        require(_tokenIds.length > 0, "invalid tokenIds");
        require(timestamp + EXP_TIME >= block.timestamp, "expiration time");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0, "invalid tokenId");
            require(!stakedState[_tokenIds[i]], "invalid stake state");
            require(ygm.ownerOf(_tokenIds[i]) == msg.sender, "invalid owner");
        }

        // verify sign message
        //_verify(_signStake(), signature);

        if (stakingTokenIds[msg.sender].length == 0) {
            stakeTotals[bytes("accountTotal")] += 1;
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            ygm.safeTransferFrom(msg.sender, address(this), _tokenId);

            // todo endtime?
            uint256 _endtime = block.timestamp + 7 * 1 days;
            StakingData memory _data = StakingData({
                account: msg.sender,
                startTime: uint64(block.timestamp),
                endTime: uint64(_endtime)
            });
            stakingDatas[_tokenId] = _data;
            emit Stake(_data.account, _tokenId, _data.startTime, _data.endTime);

            //stakingTokenIds
            stakingTokenIds[msg.sender].push(_tokenId);

            //stakeTokenIds
            uint8 _state = 0;
            for (uint256 j = 0; j < stakeTokenIds[msg.sender].length; j++) {
                if (stakeTokenIds[msg.sender][j] == _tokenId) _state = 1;
            }
            if (_state == 0) stakeTokenIds[msg.sender].push(_tokenId);

            if (!stakedState[_tokenId]) {
                stakeTotals[bytes("ygmTotal")] += 1;
                stakedState[_tokenId] = true;
            }
        }
        return true;
    }

    function unStake(uint256[] calldata _tokenIds)
        external
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(_tokenIds.length > 0, "invalid tokenIds");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            require(_tokenId > 0, "invalid tokenId");
            StakingData storage _data = stakingDatas[_tokenId];
            require(_data.account == msg.sender, "invalid account");
            require(stakedState[_tokenId], "invalid stake state");

            // safeTransferFrom
            ygm.safeTransferFrom(address(this), _data.account, _tokenId);
        }
        return true;
    }
}
