// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelpConfig is CodeConstants, Script {
    error HelpConfig__Ivalid();
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }
    NetworkConfig public localNetwoekConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelpConfig__Ivalid();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
                callbackGasLimit: 500000,
                subscriptionId: 0,
                link: 0x514910771AF9Ca656af840dff83E8264EcF986CA
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetwoekConfig.vrfCoordinator != address(0)) {
            return localNetwoekConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoodrinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        vm.stopBroadcast();

        localNetwoekConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoodrinatorMock),
            gasLane: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
            callbackGasLimit: 500000,
            subscriptionId: 0
        });
        return localNetwoekConfig;
    }
}
