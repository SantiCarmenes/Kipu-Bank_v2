// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


 /// @title MockV3Aggregator
 /// @notice A mock contract for the Chainlink V3 Aggregator, used for testing.
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 public constant DECIMALS = 8;
    int256 public s_latestAnswer;

    constructor(int256 _initialAnswer) {
        s_latestAnswer = _initialAnswer;
    }

    /// @notice Updates the latest answer for the mock price feed.
    /// @param _newAnswer The new price to be set.
    function updateAnswer(int256 _newAnswer) external {
        s_latestAnswer = _newAnswer;
    }

    /// -----------------------------------------------------------------------------------------------
    ///                                 AggregatorV3Interface
    /// -----------------------------------------------------------------------------------------------

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    function description() external pure override returns (string memory) {
        return "Mock V3 Aggregator";
    }
    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, s_latestAnswer, 0, 0, 0);
    }
    
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, s_latestAnswer, 0, 0, 0);
    }
}