// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelpConfig, CodeConstants} from "script/HelpreConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

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

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUT = 3 ether;

    function fundSubUsingConfig() public {
        HelpConfig helpConfig = new HelpConfig();
        address vrfCoordinator = helpConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helpConfig.getConfig().subscriptionId;
        address linkToken = helpConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscripcionId,
        address linkToken
    ) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscripcionId,
                FUND_AMOUT * 100
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUT,
                abi.encode(subscripcionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubUsingConfig();
    }
}

contract AddConsummer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelpConfig helpConfig = new HelpConfig();
        uint256 subId = helpConfig.getConfig().subscriptionId;
        address vrfCoordinator = helpConfig.getConfig().vrfCoordinator;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId);
    }

    function addConsumer(
        address contractToVrf,
        address vrfCoordinator,
        uint256 subId
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
