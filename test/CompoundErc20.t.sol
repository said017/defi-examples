// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CompoundErc20.sol";
import "../src/interfaces/compound.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract CompoundTest is Test {
    uint256 mainnetFork;

    address private whaleAddress;
    address private tokenAddress;
    address private c_tokenAddress;

    TestCompoundErc20 private testCompound;
    IERC20 private token;
    CErc20 private cToken;

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    function setUp() public {
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL);

        whaleAddress = 0x670D5ea78C501F1b7181F337093b39BA501d3a6A;
        tokenAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        c_tokenAddress = 0xccF4429DB6322D5C611ee964527D42E5d685DD6a;
        testCompound = new TestCompoundErc20(tokenAddress, c_tokenAddress);
        token = IERC20(tokenAddress);
        cToken = CErc20(c_tokenAddress);
        console.log("Whale WBTC balance before transfer: ");
        console.logUint(token.balanceOf(whaleAddress));
        vm.startPrank(whaleAddress);
        token.transfer(msg.sender, 2 * 10 ** 8);
        vm.stopPrank();
        console.log("Whale WBTC balance after transfer: ");
        console.log(token.balanceOf(whaleAddress));
        console.log("msg.sender WBTC balance after transfer: ");
        console.log(token.balanceOf(msg.sender));
    }

    // manage multiple forks in the same test
    function testIsForkWork() public {
        assertEq(vm.activeFork(), mainnetFork);
    }

    function testSupplyAndRedeem() public {
        // impersonate as the whale
        vm.startPrank(whaleAddress);
        token.approve(address(testCompound), 1 * 10 ** 8);
        testCompound.supply(1 * 10 ** 8);
        (uint256 exchangeRate, uint256 supplyRate) = testCompound.getInfo();
        uint256 estimateBalance = testCompound.estimateBalanceOfUnderlying();
        uint256 balanceUnderlying = testCompound.estimateBalanceOfUnderlying();

        console.log(
            "ExchangeRate is : %s and supplyRate is : %s",
            exchangeRate,
            supplyRate
        );
        console.log(
            "estimateBalance is : %s and balanceUnderlying is : %s",
            estimateBalance,
            balanceUnderlying
        );
        console.log(
            "token Balance is : %s and cTokenBalance is : %s",
            token.balanceOf((address(testCompound))),
            cToken.balanceOf((address(testCompound)))
        );
        console.log("========ROLL==========");
        vm.roll(block.number + 10000);
        (uint256 exchangeRateAfter, uint256 supplyRateAfter) = testCompound
            .getInfo();
        uint256 estimateBalanceAfter = testCompound
            .estimateBalanceOfUnderlying();
        uint256 balanceUnderlyingAfter = testCompound
            .estimateBalanceOfUnderlying();
        console.log(
            "ExchangeRate now is : %s and supplyRate now is : %s",
            exchangeRateAfter,
            supplyRateAfter
        );
        console.log(
            "estimateBalance now is : %s and balanceUnderlying now is : %s",
            estimateBalanceAfter,
            balanceUnderlyingAfter
        );
        uint256 redeemAmount = cToken.balanceOf((address(testCompound)));

        testCompound.redeem(redeemAmount);

        (uint256 exchangeRateAfter2, uint256 supplyRateAfter2) = testCompound
            .getInfo();

        uint256 estimateBalanceAfter2 = testCompound
            .estimateBalanceOfUnderlying();
        uint256 balanceUnderlyingAfter2 = testCompound
            .estimateBalanceOfUnderlying();

        console.log(
            "token Balance now is : %s and cTokenBalance now is : %s",
            token.balanceOf((address(testCompound))),
            cToken.balanceOf((address(testCompound)))
        );

        console.log(
            "estimateBalance now is : %s and balanceUnderlying now is : %s",
            estimateBalanceAfter2,
            balanceUnderlyingAfter2
        );

        console.log(
            "ExchangeRate now is : %s and supplyRate now is : %s",
            exchangeRateAfter2,
            supplyRateAfter2
        );

        vm.stopPrank();
    }
}
