// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../src/FarmingContract/MasterChef.sol";
import "../test/MasterChefTest/TestToken.sol";

contract AxoraScript is Script {
    MasterChef public masterchef;
    TokenContract public atoken;

    function setUp() public {}

    function run() public {
        uint256 deployerPkey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPkey);
        atoken = new TokenContract();
        masterchef = new MasterChef(atoken, 0xe97a4C739b738e57539566547c3757ecb1bA223a, 5, block.number);
        vm.stopBroadcast();
    }
}
