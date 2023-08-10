// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IStargateRouterBase {
    //for Router
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;
}

interface IStargateRouter is IStargateRouterBase {
    //for RouterETH
    function swapETH(
        uint16 _dstChainId, // _refundAddressdestination Stargate chainId
        address payable, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;

    function poolId() external view returns (uint256);

    function stargateRouter() external view returns (address);

    function stargateEthVault() external view returns (address);
}
