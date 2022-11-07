// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YgmMarket is Ownable {
    mapping(address => bool) public noSell;

    uint256 maxFee = 10000;
    uint256 defFee;
    address platformAddress;
    mapping(address => uint256) platformFee;

    mapping(address => uint256) public businessFee;
    mapping(address => address) public businessAddress;
    mapping(address => address) public payContract;

    mapping(address => mapping(uint256 => uint256)) tokenAmount;

    mapping(address => mapping(uint256 => bool)) isLock;

    event BuildProject(
        address indexed _contract,
        address _payContract,
        uint256 _businessFee,
        address _businessAddress
    );
    event Shelves(
        address indexed seller,
        address indexed _contract,
        uint256 indexed tokenId,
        address _payContract,
        uint256 amount,
        uint256 timestamp
    );
    event Cancel(
        address indexed seller,
        address indexed _contract,
        uint256 indexed tokenId,
        address _payContract,
        uint256 amount,
        uint256 timestamp
    );
    event Buy(
        address indexed seller,
        address indexed buyer,
        address _contract,
        uint256 indexed tokenId,
        address _payContract,
        uint256 amount,
        uint256 platformRate,
        uint256 businessRate,
        uint256 timestamp
    );

    constructor(address _address, uint256 _rate) {
        setPlatformAddress(_address);
        setPlatformDefFee(_rate);
    }

    function getPlatformAddress() external view onlyOwner returns (address) {
        return platformAddress;
    }

    function getPlatformFee(address _contract) public view returns (uint256) {
        if (address(0) == _contract) {
            return defFee;
        } else {
            return
                0 == platformFee[_contract] ? defFee : platformFee[_contract];
        }
    }

    function getSellAmount(address _contract, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return tokenAmount[_contract][_tokenId];
    }

    function _getFee(
        uint256 _amount,
        uint256 _platformRate,
        uint256 _businessRate
    ) private view returns (uint256) {
        uint256 sumRate = _platformRate + _businessRate;
        return (_amount * sumRate) / maxFee;
    }

    function buildProject(
        address _contract,
        address _payContract,
        uint256 _businessFee,
        address _businessAddress
    ) external _nft_owner(_contract) {
        payContract[_contract] = _payContract;

        uint256 feeTotal = _businessFee + getPlatformFee(_contract);
        require(feeTotal < maxFee, "Fee too large");
        businessFee[_contract] = _businessFee;

        if (address(0) == _businessAddress) {
            address sender = _msgSender();
            businessAddress[_contract] = sender;
        } else {
            businessAddress[_contract] = _businessAddress;
        }

        emit BuildProject(
            _contract,
            _payContract,
            _businessFee,
            _businessAddress
        );
    }

    // _contract tokenId price
    function shelves(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(!noSell[_contract], "The nft can not sell");

        require(0 == tokenAmount[_contract][tokenId], "Nft is selling");

        address sender = _msgSender();
        IERC721 nft = IERC721(_contract);
        require(
            sender == IERC721(_contract).ownerOf(tokenId),
            "Nft owner is not sender"
        );

        require(address(this) == nft.getApproved(tokenId), "Nft unapprove");

        tokenAmount[_contract][tokenId] = amount;

        emit Shelves(
            sender,
            _contract,
            tokenId,
            address(0) == payContract[_contract]
                ? address(0)
                : payContract[_contract],
            amount,
            block.timestamp
        );
    }

    function cancel(address _contract, uint256 tokenId) external {
        require(0 < tokenAmount[_contract][tokenId], "Nft is canceled");

        address sender = _msgSender();

        IERC721 nft = IERC721(_contract);

        require(sender == nft.ownerOf(tokenId), "Nft owner is not sender");

        uint256 sellAmount = tokenAmount[_contract][tokenId];
        tokenAmount[_contract][tokenId] = 0;

        emit Cancel(
            sender,
            _contract,
            tokenId,
            address(0) == payContract[_contract]
                ? address(0)
                : payContract[_contract],
            sellAmount,
            block.timestamp
        );
    }

    function buy(address _contract, uint256 tokenId)
        external
        payable
        locked(_contract, tokenId)
    {
        require(!noSell[_contract], "The nft can not sell");

        uint256 sellAmount = tokenAmount[_contract][tokenId];
        require(0 < sellAmount, "Nft already buyed");

        IERC721 nft = IERC721(_contract);
        address _nftOwner = nft.ownerOf(tokenId);
        address _sender = _msgSender();

        uint256 _platformRate = getPlatformFee(_contract);
        uint256 _businessRate = businessFee[_contract];
        uint256 fee = _getFee(sellAmount, _platformRate, _businessRate);

        address payType = payContract[_contract];
        if (address(0) == payType) {
            require(msg.value == sellAmount, "Pay amount invalid");
            payable(platformAddress).transfer(fee);
            payable(_nftOwner).transfer(sellAmount - fee);
        } else {
            IERC20 erc = IERC20(payType);
            uint256 _allowance = erc.allowance(_sender, address(this));
            require(
                _allowance >= sellAmount,
                "Insufficient number of authorizations"
            );
            erc.transferFrom(_sender, platformAddress, fee);
            erc.transferFrom(_sender, _nftOwner, sellAmount - fee);
        }

        nft.safeTransferFrom(_nftOwner, _sender, tokenId);
        tokenAmount[_contract][tokenId] = 0;

        emit Buy(
            _nftOwner,
            _sender,
            _contract,
            tokenId,
            payType,
            sellAmount,
            _platformRate,
            _businessRate,
            block.timestamp
        );
    }

    function swichSell(address _contract) external onlyOwner {
        noSell[_contract] = !noSell[_contract];
    }

    function setPlatformDefFee(uint256 _amount) public onlyOwner {
        defFee = _amount;
    }

    function setPlatformAddress(address _address) public onlyOwner {
        platformAddress = _address;
    }

    function setPlatformFee(address _contract, uint256 _amount)
        external
        onlyOwner
    {
        platformFee[_contract] = _amount;
    }

    // check nft owner
    modifier _nft_owner(address _contract) {
        address sender = _msgSender();

        address _owner = Ownable(_contract).owner();

        require(_owner == sender, "Not owner");

        _;
    }

    modifier locked(address _contract, uint256 tokenId) {
        require(!isLock[_contract][tokenId], "Nft is buying");
        isLock[_contract][tokenId] = true;
        _;
        isLock[_contract][tokenId] = false;
    }
}
