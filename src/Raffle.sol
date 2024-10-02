// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

/**
 * @title Raffle
 * @author Gergely Gere
 * @notice  practice
 */

contract Raffle is VRFConsumerBaseV2Plus {
    error Rafflec__NotEnoughEth();
    error Rafflec__TrancvelFailed();
    error Rafflec__NotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    enum RafflesState {
        OPEN,
        CALCULATIN
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_subscriptionId;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStap;
    address private s_recentWinner;
    RafflesState private s_raffelState;

    //Events

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStap = block.timestamp;
        s_raffelState = RafflesState.OPEN;
    }

    function enterRaffle() external payable {
        //require(msg.value >= i_entranceFee, "Not enough money ");

        if (msg.value < i_entranceFee) {
            revert Rafflec__NotEnoughEth();
        }
        if (s_raffelState != RafflesState.OPEN) {
            revert Rafflec__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     *@dev If the lotery is ready to have a winner picked.
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        external
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStap) >= i_interval);
        bool isOpen = s_raffelState == RafflesState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function pickWinner() external {
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffelState)
            );
        }
        s_raffelState = RafflesState.CALCULATIN;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        // Now pass the request struct to a calldata variable before passing it to the function
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];

        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lastTimeStap = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Rafflec__TrancvelFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    function getEnterRaffle() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RafflesState) {
        return s_raffelState;
    }
}
