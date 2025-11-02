// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// import {console} from "forge-std/Test.sol";

import {IERC20} from "../interfaces/IERC20.sol";
import {IPoolManager} from "../interfaces/IPoolManager.sol";
import {IUnlockCallback} from "../interfaces/IUnlockCallback.sol";
import {CurrencyLib} from "../libraries/CurrencyLib.sol";

contract Flash is IUnlockCallback {
    using CurrencyLib for address;

    IPoolManager public immutable poolManager;
    // Contract address to test flash loan
    address private immutable tester;

    modifier onlyPoolManager() {
        require(msg.sender == address(poolManager), "not pool manager");
        _;
    }

    constructor(address _poolManager, address _tester) {
        poolManager = IPoolManager(_poolManager);
        tester = _tester;
    }

    receive() external payable {}

    /// @notice pass Flash loan logic inside unlockCallback and call flash function
    function unlockCallback(bytes calldata data)
        external
        onlyPoolManager
        returns (bytes memory)
    {
        // Decode the data to get borrower, currency, and amount
        (address currency, uint256 amount) = abi
            .decode(data, (address, uint256));
        
        // Borrow
        poolManager.take({currency: currency, to: address(this), amount: amount});

        // You would write your flash loan logic here
        (bool ok,) = tester.call("");
        require(ok, "test failed");

        // Repay
        poolManager.sync(currency);

        // if currency is zero address then its native currency
        if (currency == address(0)) {
            poolManager.settle{value: amount}();
        } else {
            IERC20(currency).transfer(address(poolManager), amount);
            poolManager.settle();
        }

        return "Asyam FlashLoan in V4";
    }

    function flash(address currency, uint256 amount) external {
        // Write your code here
        poolManager.unlock(
            abi.encode(currency, amount)
            // 1.       USDC   ,1000 USDC
        );
    }
}
