// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721URIStorage is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public isStart;

    string openedUrl;

    uint256 lastOpenTokenId;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    function start() external onlyOwner {
        isStart = !isStart;
    }

    function open(string memory url, uint256 lastTokenId) external onlyOwner {
        if (0 == bytes(openedUrl).length) {
            openedUrl = url;
        }

        require(
            0 < lastTokenId &&
                lastOpenTokenId < lastTokenId &&
                lastTokenId <= totalSupply(),
            "Invalid tokenid"
        );

        lastOpenTokenId = lastTokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        if (bytes(openedUrl).length > 0 && tokenId <= lastOpenTokenId) {
            return string(abi.encodePacked(openedUrl, "/", tokenId.toString()));
        }

        return _baseURI();
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract YGMint is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter = Counters.Counter(1);

    // uint mintTotal = 6666;

    // uint teamMax = 666;
    // uint teamMint = 0;

    // uint mintMax = 12;
    // uint mintFee = 10;

    // uint mintEveryAmount = 12 * 10 ** 17;
    // uint firstLeave = 1 * 10 ** 17;
    // uint secondtLeave = 5 * 10 ** 16;

    uint256 mintTotal = 666;

    uint256 teamMax = 66;
    uint256 teamMint = 0;

    uint256 mintMax = 12;
    uint256 mintFee = 10;

    uint256 mintEveryAmount = 12 * 10**15;
    uint256 firstLeave = 1 * 10**15;
    uint256 secondtLeave = 5 * 10**14;

    mapping(address => bool) public isMint;

    mapping(address => address payable) recommender;

    constructor() ERC721("YGM", "YGM") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmPAcZGzXzcrCfs399nASK2SJGEByjZr3atBpGML4vzfj1";
    }

    function getAmount(uint256 mintCount) external view returns (uint256) {
        require(
            totalSupply() + mintCount <= mintTotal,
            "Maximum mint quantity exceeded"
        );
        address minter = _msgSender();
        uint256 balanceMiner = balanceOf(minter);
        uint256 balanceWill = balanceMiner + mintCount;
        require(0 < mintCount && balanceWill <= mintMax, "Invalid quantity");
        if (balanceWill > mintFee) {
            if (balanceMiner < mintFee) {
                uint256 feeCount = mintFee - balanceMiner;
                return feeCount * mintEveryAmount;
            } else {
                return 0;
            }
        } else {
            return mintCount * mintEveryAmount;
        }
    }

    function safeMint(address payable _recommender, uint256 mintCount)
        external
        payable
        checkRecommender(_recommender)
    {
        require(isStart, "Not started");

        require(
            totalSupply() + mintCount <= mintTotal,
            "Maximum mint quantity exceeded"
        );

        address minter = _msgSender();
        uint256 balanceMiner = balanceOf(minter);
        uint256 balanceWill = balanceMiner + mintCount;
        require(0 < mintCount && balanceWill <= mintMax, "Invalid quantity");

        if (balanceWill > mintFee) {
            if (balanceMiner < mintFee) {
                uint256 feeCount = mintFee - balanceMiner;
                uint256 mintAmount = feeCount * mintEveryAmount;
                require(
                    mintAmount <= msg.value,
                    "Insufficient payment quantity"
                );
                if (mintAmount < msg.value) {
                    payable(minter).transfer(msg.value - mintAmount);
                }
                rewardRecommender(minter, feeCount);
            } else if (msg.value > 0) {
                payable(minter).transfer(msg.value);
            }
        } else {
            uint256 mintAmount = mintCount * mintEveryAmount;
            require(mintAmount <= msg.value, "Insufficient payment quantity");
            if (mintAmount < msg.value) {
                payable(minter).transfer(msg.value - mintAmount);
            }
            rewardRecommender(minter, mintCount);
        }

        for (uint256 i = 0; i < mintCount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(minter, tokenId);
        }

        if (!isMint[minter]) {
            isMint[minter] = true;
        }
    }

    function mint(address to, uint256 count) external onlyOwner {
        require(teamMint < teamMax, "Mint end");
        require(count > 0, "count can not be zero");
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
        teamMint += count;

        if (!isMint[to]) {
            isMint[to] = true;
        }
    }

    function withdrawal(address payable to, uint256 amount) external onlyOwner {
        require(address(0) != to, "To can not be zero");
        to.transfer(amount);
    }

    function rewardRecommender(address minter, uint256 count) private {
        address zero = address(0);

        address payable firstRecommender = recommender[minter];
        if (zero != firstRecommender && isMint[firstRecommender]) {
            firstRecommender.transfer(firstLeave * count);
        }

        address payable secondRecommender = recommender[firstRecommender];
        if (zero != secondRecommender && isMint[secondRecommender]) {
            secondRecommender.transfer(secondtLeave * count);
        }
    }

    modifier checkRecommender(address payable _recommender) {
        if (recommender[msg.sender] == address(0)) {
            require(address(0) != _recommender, "Recommender can not be zero");
            require(
                msg.sender != _recommender,
                "Recommender can not to be same"
            );
            require(isMint[_recommender], "Recommender no mint");
            recommender[msg.sender] = _recommender;
        }
        _;
    }
}
