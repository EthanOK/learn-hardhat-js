// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity >=0.7.0 <0.9.0;

interface interStorage {
    function readDataNotRerurn() external view returns (uint256);
}

contract AssemblyStorage {
    uint256 number = 100; // slot 0
    IERC20 erc20 = IERC20(address(0)); // slot 1
    uint256 count = 200; // slot 2

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        assembly {
            sstore(number.slot, num)
        }
        // number = num;
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        assembly {
            let num := sload(number.slot)
            mstore(0, num)
            return(0, 32)
        }
        //return number;
    }

    function readData() public view returns (uint256) {
        assembly {
            let num := sload(number.slot)
            let point := mload(0x40)
            mstore(point, num)
            return(point, 32)
        }
        //return number;
    }

    function readDataNotReturn() public view {
        assembly {
            let num := sload(number.slot)
            let point := mload(0x40)
            mstore(point, num)
            return(point, 32)
        }
        //return number;
    }

    function getSlot() public pure returns (uint256 nums, uint256 cous) {
        assembly {
            nums := number.slot
            cous := count.slot
        }
        // 0 2
    }
}
