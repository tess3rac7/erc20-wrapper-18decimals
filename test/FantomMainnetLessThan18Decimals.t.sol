// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "ERC20/extensions/IERC20Metadata.sol";
import "ERC20/utils/SafeERC20.sol";

import "src/ERC20Wrapper18Decimals.sol";

contract FantomMainnetLessThan18DecimalsTest is Test {
    using SafeERC20 for IERC20Metadata;

    // addresses for fantom mainnet
    IERC20Metadata USDC = IERC20Metadata(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);

    // holders as of block 41105130
    address USDCHolder = 0xdDf169Bf228e6D6e701180E2e6f290739663a784;

    ERC20Wrapper18Decimals USDCWrapper;

    function setUp() public {
        USDCWrapper = new ERC20Wrapper18Decimals(USDC);
    }

    function testWrapZeroAmount() public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalBefore = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalBefore = USDC.balanceOf(address(USDCWrapper));
        
        vm.startPrank(USDCHolder);
        USDC.safeIncreaseAllowance(address(USDCWrapper), 1000000);
        USDCWrapper.wrap(0);
        vm.stopPrank();

        uint256 holderUSDCBalAfter = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalAfter = USDC.balanceOf(address(USDCWrapper));

        assertEq(holderUSDCBalBefore, holderUSDCBalAfter);
        assertEq(holderUSDCWrapperBalBefore, holderUSDCWrapperBalAfter);
        assertEq(holderUSDCWrapperBalAfter, 0);
        assertEq(wrapperUSDCBalBefore, wrapperUSDCBalAfter);
        assertEq(wrapperUSDCBalAfter, 0);
    }

    function testWrapNonZeroAmountWithoutAllowance(uint256 _amount) public {
        vm.assume(_amount != 0);
        vm.expectRevert(bytes("WERC10: request exceeds allowance"));
        vm.prank(USDCHolder);
        USDCWrapper.wrap(_amount);
    }

    function testWrapNonZeroAmountWithAllowance(uint256 _amount) public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);
        uint256 holderUSDCWrapperBalBefore = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalBefore = USDC.balanceOf(address(USDCWrapper));
        
        vm.startPrank(USDCHolder);
        USDC.safeIncreaseAllowance(address(USDCWrapper), _amount);
        USDCWrapper.wrap(_amount);
        vm.stopPrank();

        uint256 holderUSDCBalAfter = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalAfter = USDC.balanceOf(address(USDCWrapper));

        assertEq(holderUSDCBalBefore - holderUSDCBalAfter, _amount);
        assertEq(holderUSDCWrapperBalBefore, 0);
        assertEq(holderUSDCWrapperBalAfter, _amount * 1_000_000_000_000); // 12 decimal place difference
        assertEq(wrapperUSDCBalBefore, 0);
        assertEq(wrapperUSDCBalAfter, _amount);
    }

    function testWrapInChunksNonZeroAmountWithAllowance(uint256 _amount) public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);
        uint256 holderUSDCWrapperBalBefore = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalBefore = USDC.balanceOf(address(USDCWrapper));
        
        uint256 wrapped = 0;
        vm.startPrank(USDCHolder);
        for (uint256 i = 0; i < 10; i++) { // in 10 chunks
            uint256 toWrap = _amount / 10;
            USDC.safeIncreaseAllowance(address(USDCWrapper), toWrap);
            USDCWrapper.wrap(toWrap);
            wrapped += toWrap;

            uint256 holderUSDCBalAfter = USDC.balanceOf(USDCHolder);
            uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);
            uint256 wrapperUSDCBalAfter = USDC.balanceOf(address(USDCWrapper));

            assertEq(holderUSDCBalBefore - holderUSDCBalAfter, wrapped);
            assertEq(holderUSDCWrapperBalBefore, 0);
            assertEq(holderUSDCWrapperBalAfter, wrapped * 1_000_000_000_000); // 12 decimal place difference
            assertEq(wrapperUSDCBalBefore, 0);
            assertEq(wrapperUSDCBalAfter, wrapped);
        }

        USDC.safeIncreaseAllowance(address(USDCWrapper), _amount - wrapped);
        USDCWrapper.wrap(_amount - wrapped);
        vm.stopPrank();

        uint256 holderUSDCBalAfter = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalAfter = USDC.balanceOf(address(USDCWrapper));

        assertEq(holderUSDCBalBefore - holderUSDCBalAfter, _amount);
        assertEq(holderUSDCWrapperBalBefore, 0);
        assertEq(holderUSDCWrapperBalAfter, _amount * 1_000_000_000_000); // 12 decimal place difference
        assertEq(wrapperUSDCBalBefore, 0);
        assertEq(wrapperUSDCBalAfter, _amount);
    }

    function testUnwrapZeroAmount(uint256 _amount) public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);

        // randomize wrapping all at once or in chunks
        if (_amount % 2 == 0) {
            testWrapNonZeroAmountWithAllowance(_amount);
        } else {
            testWrapInChunksNonZeroAmountWithAllowance(_amount);
        }

        uint256 holderUSDCBalAfter = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalAfter = USDC.balanceOf(address(USDCWrapper));

        vm.prank(USDCHolder);
        USDCWrapper.unwrap(0);

        uint256 holderUSDCBalFinal = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalFinal = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalFinal = USDC.balanceOf(address(USDCWrapper));

        assertEq(holderUSDCBalAfter, holderUSDCBalFinal);
        assertEq(holderUSDCWrapperBalAfter, holderUSDCWrapperBalFinal);
        assertEq(wrapperUSDCBalAfter, wrapperUSDCBalFinal);
    }

    function testUnwrapMoreThanBalance(uint256 _amount) public {
        vm.assume(_amount != 0);
        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        vm.prank(USDCHolder);
        USDCWrapper.unwrap(_amount);

        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);

        // randomize wrapping all at once or in chunks
        if (_amount % 2 == 0) {
            testWrapNonZeroAmountWithAllowance(_amount);
        } else {
            testWrapInChunksNonZeroAmountWithAllowance(_amount);
        }

        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);

        vm.expectRevert(bytes("ERC20: burn amount exceeds balance"));
        vm.prank(USDCHolder);
        USDCWrapper.unwrap(holderUSDCWrapperBalAfter + 1);
    }

    function testUnwrapAllAtOnce(uint256 _amount) public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);

        // randomize wrapping all at once or in chunks
        if (_amount % 2 == 0) {
            testWrapNonZeroAmountWithAllowance(_amount);
        } else {
            testWrapInChunksNonZeroAmountWithAllowance(_amount);
        }

        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);

        vm.prank(USDCHolder);
        USDCWrapper.unwrap(holderUSDCWrapperBalAfter);

        uint256 holderUSDCBalFinal = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalFinal = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalFinal = USDC.balanceOf(address(USDCWrapper));

        assertEq(holderUSDCBalFinal, holderUSDCBalBefore);
        assertEq(holderUSDCWrapperBalFinal, 0);
        assertEq(wrapperUSDCBalFinal, 0);
    }

    function testUnwrapInChunks(uint256 _amount) public {
        uint256 holderUSDCBalBefore = USDC.balanceOf(USDCHolder);
        vm.assume(_amount <= holderUSDCBalBefore);

        // randomize wrapping all at once or in chunks
        if (_amount % 2 == 0) {
            testWrapNonZeroAmountWithAllowance(_amount);
        } else {
            testWrapInChunksNonZeroAmountWithAllowance(_amount);
        }

        uint256 holderUSDCWrapperBalAfter = USDCWrapper.balanceOf(USDCHolder);

        uint256 unwrapped = 0;
        vm.startPrank(USDCHolder);
        for (uint256 i = 0; i < 10; i++) {
            uint256 toUnwrap = holderUSDCWrapperBalAfter / 10;
            USDCWrapper.unwrap(toUnwrap);
            unwrapped += toUnwrap;

            uint256 holderUSDCBalFinal = USDC.balanceOf(USDCHolder);
            uint256 holderUSDCWrapperBalFinal = USDCWrapper.balanceOf(USDCHolder);
            uint256 wrapperUSDCBalFinal = USDC.balanceOf(address(USDCWrapper));

            assertEq(holderUSDCWrapperBalFinal, holderUSDCWrapperBalAfter - unwrapped);
            assertEq(holderUSDCBalBefore, holderUSDCBalFinal + wrapperUSDCBalFinal);
        }

        USDCWrapper.unwrap(holderUSDCWrapperBalAfter - unwrapped);
        vm.stopPrank();

        uint256 holderUSDCBalFinal = USDC.balanceOf(USDCHolder);
        uint256 holderUSDCWrapperBalFinal = USDCWrapper.balanceOf(USDCHolder);
        uint256 wrapperUSDCBalFinal = USDC.balanceOf(address(USDCWrapper));

        assertApproxEqAbs(holderUSDCBalFinal, holderUSDCBalBefore, 10);
        assertApproxEqAbs(wrapperUSDCBalFinal, 0, 10);
        assertEq(holderUSDCWrapperBalFinal, 0);
    }
}
