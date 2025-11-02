// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IExtsload} from "./IExtsload.sol";
import {IExttload} from "./IExttload.sol";
import {PoolKey} from "../types/PoolKey.sol";
import {ModifyLiquidityParams, SwapParams} from "../types/PoolOperation.sol";

interface IPoolManager is IExtsload, IExttload {
    /// @notice Thrown when a currency is not netted out after the contract is unlocked
    error CurrencyNotSettled();

    /// @notice Thrown when trying to interact with a non-initialized pool
    error PoolNotInitialized();

    /// @notice Thrown when unlock is called, but the contract is already unlocked
    error AlreadyUnlocked();

    /// @notice Thrown when a function is called that requires the contract to be unlocked, but it is not
    error ManagerLocked();

    /// @notice Pools are limited to type(int16).max tickSpacing in #initialize, to prevent overflow
    error TickSpacingTooLarge(int24 tickSpacing);

    /// @notice Pools must have a positive non-zero tickSpacing passed to #initialize
    error TickSpacingTooSmall(int24 tickSpacing);

    /// @notice PoolKey must have currencies where address(currency0) < address(currency1)
    error CurrenciesOutOfOrderOrEqual(address currency0, address currency1);

    /// @notice Thrown when a call to updateDynamicLPFee is made by an address that is not the hook,
    /// or on a pool that does not have a dynamic swap fee.
    error UnauthorizedDynamicLPFeeUpdate();

    /// @notice Thrown when trying to swap amount of 0
    error SwapAmountCannotBeZero();

    ///@notice Thrown when native currency is passed to a non native settlement
    error NonzeroNativeValue();

    /// @notice Thrown when `clear` is called with an amount that is not exactly equal to the open currency delta.
    error MustClearExactPositiveDelta();

    // Pass PoolKey struct to identify the pool 
    function unlock(bytes calldata data) external returns (bytes memory);

    // initialize a pool with given PoolKey and starting sqrtPriceX96
    function initialize(PoolKey memory key, uint160 sqrtPriceX96)
        external
        returns (int24 tick);

    // modify liquidity in a pool identified by PoolKey with given ModifyLiquidityParams
    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes calldata hookData
    ) external returns (int256 callerDelta, int256 feesAccrued);

    // swap currencies in a pool identified by PoolKey with given SwapParams
    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes calldata hookData
    ) external returns (int256 swapDelta);

    // donate liquidity to a pool identified by PoolKey
    function donate(
        PoolKey memory key,
        uint256 amount0,
        uint256 amount1,
        bytes calldata hookData
    ) external returns (int256);

    // sync is used to update the pool manager's internal accounting of currency deltas for a given currency.
    function sync(address currency) external; 

    // take allows the caller to withdraw currency from the pool manager, increasing their negative delta.
    function take(address currency, address to, uint256 amount) external;

    // settle is a mechanism to ensure that after an unlock, all currency deltas are netted out.
    // If there is a positive delta for any currency, that currency must be paid to the pool manager before
    // further interactions can occur. If there is a negative delta for any currency, the pool manager will pay that amount to the caller.
    function settle() external payable returns (uint256 paid);

    // settleFor is similar to settle, but allows specifying a recipient for any currency paid out by the pool manager.
    function settleFor(address recipient)
        external
        payable
        returns (uint256 paid);

    function clear(address currency, uint256 amount) external;

    function mint(address to, uint256 id, uint256 amount) external;

    function burn(address from, uint256 id, uint256 amount) external;

    function updateDynamicLPFee(PoolKey memory key, uint24 newDynamicLPFee)
        external;
}
