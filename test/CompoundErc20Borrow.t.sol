// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CompoundErc20.sol";
import "../src/interfaces/compound.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract CompoundTestBorrow is Test {
    uint256 mainnetFork;

    address private whaleAddress;
    address private tokenAddress;
    address private c_tokenAddress;

    address private tokenToBorrowAddress;
    address private c_tokenToBorrowAddress;
    address private borrowWhaleAddress;

    TestCompoundErc20 private testCompound;
    IERC20 private token;
    CErc20 private cToken;

    IERC20 private borrowToken;
    CErc20 private cBorrowToken;

    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    function setUp() public {
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL);

        whaleAddress = 0x670D5ea78C501F1b7181F337093b39BA501d3a6A;
        tokenAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        c_tokenAddress = 0xccF4429DB6322D5C611ee964527D42E5d685DD6a;

        tokenToBorrowAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        c_tokenToBorrowAddress = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        borrowWhaleAddress = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

        testCompound = new TestCompoundErc20(tokenAddress, c_tokenAddress);
        token = IERC20(tokenAddress);
        cToken = CErc20(c_tokenAddress);

        borrowToken = IERC20(tokenToBorrowAddress);
        cBorrowToken = CErc20(c_tokenToBorrowAddress);

        // vm.startPrank(whaleAddress);

        // vm.stopPrank();
        console.log("Whale WBTC balance before: ");
        console.log(token.balanceOf(whaleAddress));
        console.log("Whale DAI balance before: ");
        console.log(borrowToken.balanceOf(borrowWhaleAddress));
    }

    // manage multiple forks in the same test
    // function testIsForkWork() public {
    //     assertEq(vm.activeFork(), mainnetFork);
    // }

    function testBorrowAndRepay() public {
        // impersonate as the whale
        vm.startPrank(whaleAddress);
        token.approve(address(testCompound), 1 * 10 ** 8);
        testCompound.supply(1 * 10 ** 8);

        // borrow
        console.log("--- borrow (before) ---");
        console.log("col factor: ");
        console.log(testCompound.getCollateralFactor() / (10 ** (18 - 2)));
        console.log("supplied: ");
        console.log(testCompound.balanceOfUnderlying());
        (uint liquidity, uint shortfall) = testCompound.getAccountLiquidity();
        console.log("liquidity: ");
        console.log(liquidity);
        console.log("price (DAI): ");
        uint price = testCompound.getPriceFeed(c_tokenToBorrowAddress);
        console.log(price);
        console.log("max borrow: ");
        uint maxBorrow = liquidity / price;
        console.log(maxBorrow);
        console.log("borrowed balance (compound): ");
        uint borrowedBalance = testCompound.getBorrowedBalance(
            c_tokenToBorrowAddress
        );
        console.log(borrowedBalance);
        console.log("borrowed balance (erc20):");
        uint tokenToBorrowBal = borrowToken.balanceOf(address(testCompound));
        console.log(tokenToBorrowBal);
        console.log("borrow rate:");
        console.log(testCompound.getBorrowRatePerBlock(c_tokenToBorrowAddress));

        testCompound.borrow(c_tokenToBorrowAddress, 18);
        console.log("--- borrow (after) ---");
        (uint liquidityAfter, uint shortfallAfter) = testCompound
            .getAccountLiquidity();
        console.log("liquidity: ");
        console.log(liquidityAfter);
        console.log("max borrow: ");
        uint priceAfter = testCompound.getPriceFeed(c_tokenToBorrowAddress);
        uint maxBorrowAfter = liquidityAfter / priceAfter;
        console.log(maxBorrowAfter);
        console.log("borrowed balance (compound): ");
        uint borrowedBalanceAfter = testCompound.getBorrowedBalance(
            c_tokenToBorrowAddress
        );
        console.log(borrowedBalanceAfter);
        console.log("borrowed balance (erc20):");
        uint tokenToBorrowBalAfter = borrowToken.balanceOf(
            address(testCompound)
        );
        console.log(tokenToBorrowBalAfter);

        // move forward
        console.log("========ROLL==========");
        vm.roll(block.number + 1000);
        (uint liquidityAfter2, uint shortfallAfter2) = testCompound
            .getAccountLiquidity();
        console.log("liquidity: ");
        console.log(liquidityAfter2);
        console.log("max borrow: ");
        uint priceAfter2 = testCompound.getPriceFeed(c_tokenToBorrowAddress);
        uint maxBorrowAfter2 = liquidityAfter2 / priceAfter2;
        console.log(maxBorrowAfter2);
        console.log("borrowed balance (compound): ");
        uint borrowedBalanceAfter2 = testCompound.getBorrowedBalance(
            c_tokenToBorrowAddress
        );
        console.log(borrowedBalanceAfter2);
        console.log("borrowed balance (erc20):");
        uint tokenToBorrowBalAfter2 = borrowToken.balanceOf(
            address(testCompound)
        );
        console.log(tokenToBorrowBalAfter2);

        vm.stopPrank();

        // repay

        vm.startPrank(borrowWhaleAddress);
        borrowToken.transfer(address(testCompound), 1000 * (10 ** 18));
        testCompound.repay(
            tokenToBorrowAddress,
            c_tokenToBorrowAddress,
            2 ** 256 - 1
        );

        console.log("========Repay==========");
        console.log("liquidity: ");
        (uint liquidityAfter3, uint shortfallAfter3) = testCompound
            .getAccountLiquidity();
        console.log(liquidityAfter3);
        console.log("max borrow: ");
        uint priceAfter3 = testCompound.getPriceFeed(c_tokenToBorrowAddress);
        uint maxBorrowAfter3 = liquidityAfter3 / priceAfter3;
        console.log(maxBorrowAfter3);
        console.log("borrowed balance (compound): ");
        uint borrowedBalanceAfter3 = testCompound.getBorrowedBalance(
            c_tokenToBorrowAddress
        );
        console.log(borrowedBalanceAfter3);
        console.log("borrowed balance (erc20):");
        uint tokenToBorrowBalAfter3 = borrowToken.balanceOf(
            address(testCompound)
        );
        console.log(tokenToBorrowBalAfter3);
    }
}
