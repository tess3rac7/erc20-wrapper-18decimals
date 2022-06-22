// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "ERC20/ERC20.sol";
import "ERC20/utils/SafeERC20.sol";

contract ERC20Wrapper18Decimals is ERC20 {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata public immutable underlying;

    constructor(IERC20Metadata _underlying)
        ERC20(string.concat(_underlying.name(), " 18 Decimals"), string.concat(_underlying.symbol(), "18"))
    {
        underlying = _underlying;
    }

    function wrap(uint256 _underlyingAmount) external {
        underlying.safeTransferFrom(msg.sender, address(this), _underlyingAmount);

        uint256 wrappedToMint = _underlyingAmount;
        if (underlying.decimals() < 18) {
            wrappedToMint *= 10**(18 - underlying.decimals());
        } else if (underlying.decimals() > 18) {
            wrappedToMint /= 10**(underlying.decimals() - 18);
        }

        _mint(msg.sender, wrappedToMint);
    }

    function unwrap(uint256 _wrappedAmount) external {
        _burn(msg.sender, _wrappedAmount);

        uint256 underlyingToSend = _wrappedAmount;
        if (underlying.decimals() < 18) {
            underlyingToSend /= 10**(18 - underlying.decimals());
        } else if (underlying.decimals() > 18) {
            underlyingToSend *= 10**(underlying.decimals() - 18);
        }

        uint256 underlyingBalance = underlying.balanceOf(address(this));
        if (underlyingToSend > underlyingBalance) {
            underlyingToSend = underlyingBalance;
        }

        underlying.safeTransfer(msg.sender, underlyingToSend);
    }
}
