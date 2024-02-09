// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Tapioca
import {ITapiocaOptionLiquidityProvision} from
    "tapioca-periph/interfaces/tap-token/ITapiocaOptionLiquidityProvision.sol";
import {ITapiocaOptionBroker} from "tapioca-periph/interfaces/tap-token/ITapiocaOptionBroker.sol";
import {MagnetarAction, MagnetarModule} from "tapioca-periph/interfaces/periph/IMagnetar.sol";
import {IYieldBoxTokenType} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {ITapiocaOFT} from "tapioca-periph/interfaces/tap-token/ITapiocaOFT.sol";
import {ICommonData} from "tapioca-periph/interfaces/common/ICommonData.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {IUSDOBase} from "tapioca-periph/interfaces/bar/IUSDO.sol";


/*
__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/**
 * @title MagnetarStorage
 * @author TapiocaDAO
 * @notice Storage contract for Magnetar & modules
 */
contract MagnetarStorage is IERC721Receiver {
    struct Call {
        bytes call;
        uint256 value;
        address target;
        MagnetarAction id;
        bool allowFailure;
    }

    ICluster public cluster;
    mapping(MagnetarModule moduleId => address moduleAddress) public modules;


    // Helpers for external usage. Not used in the contract.
    uint8 public constant MAGNETAR_ACTION_PERMIT = 0;
    uint8 public constant MAGNETAR_ACTION_WRAP = 1;
    uint8 public constant MAGNETAR_ACTION_MARKET = 2;
    uint8 public constant MAGNETAR_ACTION_TAP_TOKEN = 3;
    uint8 public constant MAGNETAR_ACTION_OFT = 4;
    uint8 public constant MAGNETAR_ACTION_ASSET_MODULE = 5;
    uint8 public constant MAGNETAR_ACTION_COLLATERAL_MODULE = 6;
    uint8 public constant MAGNETAR_ACTION_MINT_MODULE = 7;
    uint8 public constant MAGNETAR_ACTION_OPTION_MODULE = 8;
    uint8 public constant MAGNETAR_ACTION_YIELDBOX_MODULE = 9;

    error Magnetar_NotAuthorized(address caller, address expectedCaller); // msg.send is neither the owner nor whitelisted by Cluster
    error Magnetar_ModuleNotFound(MagnetarModule module); // Module not found
    error Magnetar_UnknownReason(); // Revert reason not recognized

    receive() external payable virtual {}

    /// =====================
    /// Public
    /// =====================
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// =====================
    /// Private
    /// =====================
    function _executeModule(MagnetarModule _module, bytes memory _data) internal returns (bytes memory returnData) {
        bool success = true;
        address module = modules[_module];
        if (module == address(0)) revert Magnetar_ModuleNotFound(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            _getRevertMsg(returnData);
        }
    }

    /**
     * @dev Check if the sender is authorized to call the contract.
     * sender is authorized if:
     *      - is the owner
     *      - is whitelisted by the cluster
     */
    function _checkSender(address _from) internal view {
        if (_from != msg.sender && !cluster.isWhitelisted(0, msg.sender)) {
            revert Magnetar_NotAuthorized(msg.sender, _from);
        }
    }

    /**
     * @dev Decodes revert messages
     */
    function _getRevertMsg(bytes memory _returnData) internal pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert Magnetar_UnknownReason();

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}
