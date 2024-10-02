// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelpConfig} from "script/HelpreConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubUsingConfig() public returns (uint256, address) {
        HelpConfig helpConfig = new HelpConfig();
        address vrfCoordinator = helpConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSub(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSub(
        address vrfCoordinator
    ) public returns (uint256, address) {
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUT = 3 ether;

    function fundSubUsingConfig() public {
        HelpConfig helpConfig = new HelpConfig();
        address vrfCoordinator = helpConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helpConfig.getConfig().subscriptionId;
    }

    function run() public {}
}
