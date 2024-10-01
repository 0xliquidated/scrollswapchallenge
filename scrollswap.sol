// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract UniswapSimpleSwap {
    using SafeERC20 for IERC20;

    // The address of the Uniswap V3 router
    ISwapRouter public immutable swapRouter;

    // WETH address, which might be useful for wrapping/unwrapping ETH
    address public immutable WETH;

    constructor(address _swapRouter, address _weth) {
        swapRouter = ISwapRouter(_swapRouter);
        WETH = _weth;
    }

    // Function to perform a simple swap
    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external returns (uint256 amountOut) {
        // Transfer tokens to this contract
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        // Approve the Uniswap router to spend these tokens
        IERC20(_tokenIn).safeIncreaseAllowance(address(swapRouter), _amountIn);

        // Define the swap path, here we assume direct swap or through WETH for simplicity
        ISwapRouter.ExactInputSingleParams memory params = 
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000, // Assuming a 0.3% fee tier, but this should match the pool fee
                recipient: _to,
                deadline: block.timestamp + 1800, // 30 minutes from now
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0 // Set to 0 for no limit, but should be used with caution in production
            });

        // Execute the swap
        amountOut = swapRouter.exactInputSingle(params);

        // Refund any leftover of the input token back to the sender if there's any
        uint256 remaining = IERC20(_tokenIn).balanceOf(address(this));
        if (remaining > 0) {
            IERC20(_tokenIn).safeTransfer(msg.sender, remaining);
        }
    }

    // This function allows the contract to receive ETH (useful if WETH is involved in swaps)
    receive() external payable {}
}