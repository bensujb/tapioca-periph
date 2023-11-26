// SPDX-License-Identifier: GPL-3.0

// contracts/oracle/OracleChainlinkSingle.sol
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SequencerCheck} from "./utils/SequencerCheck.sol";
import "./modules/ModuleChainlinkSingle.sol";
import "./OracleAbstract.sol";

/// @title OracleChainlinkSingle
/// @author Angle Core Team, modified by Tapioca
/// @notice Oracle contract, one contract is deployed per collateral/stablecoin pair
/// @dev This contract concerns an oracle that only uses Chainlink and a single pool
/// @dev This is mainly going to be the contract used for the USD/EUR pool (or for other fiat currencies)
/// @dev Like all oracle contracts, this contract is an instance of `OracleAstract` that contains some
/// base functions
contract OracleChainlinkSingle is
    OracleAbstract,
    ModuleChainlinkSingle,
    SequencerCheck,
    ReentrancyGuard
{
    /// @notice Constructor for the oracle using a single Chainlink pool
    /// @param _poolChainlink Chainlink pool address
    /// @param _isChainlinkMultiplied Whether we should multiply or divide by the Chainlink rate the
    /// in-currency amount to get the out-currency amount
    /// @param _inBase Number of units of the in-currency
    /// @param _description Description of the assets concerned by the oracle
    /// @param _admin Address of the admin of the oracle
    constructor(
        address _poolChainlink,
        uint8 _isChainlinkMultiplied,
        uint256 _inBase,
        uint32 stalePeriod,
        address[] memory guardians,
        bytes32 _description,
        address _sequencerUptimeFeed,
        address _admin
    )
        ModuleChainlinkSingle(
            _poolChainlink,
            _isChainlinkMultiplied,
            stalePeriod,
            guardians
        )
        SequencerCheck(_sequencerUptimeFeed)
        AccessControlDefaultAdminRules(3 days, _admin)
    {
        inBase = _inBase;
        description = _description;
    }

    /// @notice Reads the rate from the Chainlink feed
    /// @return rate The current rate between the in-currency and out-currency
    function read() external view override returns (uint256 rate) {
        (rate, ) = _quoteChainlink(BASE);
    }

    /// @notice Converts an in-currency quote amount to out-currency using Chainlink's feed
    /// @param quoteAmount Amount (in the input collateral) to be converted in out-currency
    /// @return Quote amount in out-currency from the base amount in in-currency
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function readQuote(
        uint256 quoteAmount
    ) external view override returns (uint256) {
        return _readQuote(quoteAmount);
    }

    /// @notice Returns Chainlink quote value twice
    /// @param quoteAmount Amount expressed in the in-currency base.
    /// @dev If quoteAmount is `inBase`, rates are returned
    /// @return The two return values are similar in this case
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readAll(
        uint256 quoteAmount
    ) internal view override returns (uint256, uint256) {
        uint256 quote = _readQuote(quoteAmount);
        return (quote, quote);
    }

    /// @notice Internal function to convert an in-currency quote amount to out-currency using Chainlink's feed
    /// @param quoteAmount Amount (in the input collateral) to be converted
    /// @dev The amount returned is expressed with base `BASE` (and not the base of the out-currency)
    function _readQuote(uint256 quoteAmount) internal view returns (uint256) {
        quoteAmount = (quoteAmount * BASE) / inBase;
        (quoteAmount, ) = _quoteChainlink(quoteAmount);
        // We return only rates with base BASE
        return quoteAmount;
    }

    /// @notice Changes the grace period for the sequencer update
    /// @param _gracePeriod New stale period (in seconds)
    function changeGracePeriod(
        uint32 _gracePeriod
    ) external override onlyRole(SEQUENCER_ROLE) {
        GRACE_PERIOD_TIME = _gracePeriod;
    }
}
