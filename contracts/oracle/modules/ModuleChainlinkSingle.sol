// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "../utils/ChainlinkUtils.sol";

/// @title ModuleChainlinkSingle
/// @author Angle Core Team
/// @notice Module Contract that is going to be used to help compute Chainlink prices
/// @dev This contract will help for an oracle using a single Chainlink price
/// @dev An oracle using Chainlink is either going to be a `ModuleChainlinkSingle` or a `ModuleChainlinkMulti`
abstract contract ModuleChainlinkSingle is ChainlinkUtils {
    /// @notice Chainlink pool to look for in the contract
    AggregatorV3Interface public immutable poolChainlink;
    /// @notice Whether the rate computed using the Chainlink pool should be multiplied to the quote amount or not
    uint8 public immutable isChainlinkMultiplied;
    /// @notice Decimals for each Chainlink pairs
    uint8 public immutable chainlinkDecimals;

    /// @notice Constructor for an oracle using only a single Chainlink
    /// @param _poolChainlink Chainlink pool address
    /// @param _isChainlinkMultiplied Whether we should multiply or divide the quote amount by the rate
    constructor(
        address _poolChainlink,
        uint8 _isChainlinkMultiplied,
        uint32 _stalePeriod,
        address[] memory guardians,
        address _sequencerUptimeFeed
    ) ChainlinkUtils(_sequencerUptimeFeed) {
        require(_poolChainlink != address(0), "105");
        poolChainlink = AggregatorV3Interface(_poolChainlink);
        chainlinkDecimals = AggregatorV3Interface(_poolChainlink).decimals();
        // There is no `GOVERNOR_ROLE` in this contract, governor has `GUARDIAN_ROLE`
        require(guardians.length > 0, "101");
        for (uint256 i = 0; i < guardians.length; i++) {
            require(guardians[i] != address(0), "0");
            _setupRole(GUARDIAN_ROLE_CHAINLINK, guardians[i]);
        }
        _setRoleAdmin(GUARDIAN_ROLE_CHAINLINK, GUARDIAN_ROLE_CHAINLINK);

        stalePeriod = _stalePeriod;
        isChainlinkMultiplied = _isChainlinkMultiplied;
    }

    /// @notice Reads oracle price using a single Chainlink pool
    /// @param quoteAmount Amount expressed with base decimal
    /// @dev If `quoteAmount` is base, the output is the oracle rate
    function _quoteChainlink(
        uint256 quoteAmount
    ) internal view returns (uint256, uint256) {
        // No need for a for loop here as there is only a single pool we are looking at
        return
            _readChainlinkFeed(
                quoteAmount,
                poolChainlink,
                isChainlinkMultiplied,
                chainlinkDecimals,
                0
            );
    }
}
