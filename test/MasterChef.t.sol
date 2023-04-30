// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/FarmingContract/MasterChef.sol";
import "./MasterChefTest/TestToken.sol";


contract MasterChefTest is Test {
    TokenContract public token;
    MasterChef public masterchef;
    

    function setUp() public {
        token = new TokenContract();
        masterchef = new MasterChef(token, address(this), 1000, block.timestamp);
        token.owner();
        token.transferOwnership(address(masterchef));
        console.log(token.owner());
    }

    function testAdd() public {
        masterchef.poolLength();
        masterchef.add(1000, token, true);
    }

    function testAddMultiplePools() public {
        masterchef.add(1000, token, true);
        masterchef.add(1000, token, true);
        masterchef.add(1000, token, true);
        masterchef.poolInfo(0);
        masterchef.poolInfo(1);
        masterchef.poolInfo(2);
        masterchef.totalAllocPoint();
    }

    function testAddMultipleAndSet() public {
        testAddMultiplePools();
        masterchef.set(1, 2000, true);
        masterchef.poolInfo(1);
        masterchef.totalAllocPoint();
    }


    function testDeposit() public {
        testAdd();
        token.mint(100);
        token.approve(address(masterchef), 50);
        masterchef.deposit(0, 50);
    }

    function testWithdraw() public {
        testDeposit();
        vm.warp(block.timestamp + 604800);
        masterchef.pendingAxora(0, address(this));
        token.balanceOf(address(masterchef));
        masterchef.withdraw(0, 50);
    }

    function testSet() public {
        testAdd();
        masterchef.set(0, 2000, true);
        masterchef.poolInfo(0);
    }

    function testPendingAxora() public {
        testDeposit();
        vm.warp(block.timestamp + 604800);
        masterchef.totalAllocPoint();
        masterchef.updatePool(0);
        masterchef.poolInfo(0);
        masterchef.pendingAxora(0, address(this));
        token.balanceOf(address(masterchef));
    }

    function testMultipleDepositAndClaim() public {
        testDeposit();
        masterchef.pendingAxora(0, address(this));
        token.balanceOf(address(masterchef));
        vm.warp(block.timestamp + 604800);
        masterchef.pendingAxora(0, address(this));
        vm.startPrank(address(0x01));
        token.mint(200);
        token.approve(address(masterchef), 100);
        masterchef.deposit(0, 100);
        masterchef.pendingAxora(0, address(this));
        masterchef.pendingAxora(0, address(0x01));
        token.balanceOf(address(masterchef));
        masterchef.poolInfo(0);
        vm.warp(block.timestamp + 100);
        masterchef.pendingAxora(0, address(0x01));
        masterchef.pendingAxora(0, address(this));
        token.balanceOf(address(masterchef));
        vm.stopPrank();
        vm.startPrank(address(0x02));
        token.mint(200);
        token.approve(address(masterchef), 200);
        masterchef.deposit(0, 200);
        masterchef.pendingAxora(0, address(this));
        masterchef.pendingAxora(0, address(0x01));
        token.balanceOf(address(masterchef));
        masterchef.poolInfo(0);
        vm.stopPrank();
        vm.warp(block.timestamp + 100);
        masterchef.withdraw(0, 50);
        vm.prank(address(0x01));
        masterchef.withdraw(0, 100);
        token.balanceOf(address(masterchef));

    }


    function testDev() public {
        masterchef.dev(address(0x01));
    }

    function testEmergencyWithdraw() public {
        testDeposit();
        masterchef.emergencyWithdraw(0);
    }

}
