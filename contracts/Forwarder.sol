// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Forwarder {
    /// Batch signature and transfer
    function payViaSignature(
        address[] calldata payer,
        uint256[] calldata amount,
        uint256[] calldata deadline,
        address[] calldata _token,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external {
        for (uint i = 0; i < payer.length; i++) {
            IToken token = IToken(_token[i]);
            token.permit(
                payer[i],
                address(this),
                amount[i],
                deadline[i],
                v[i],
                r[i],
                s[i]
            );
            token.transferFrom(payer[i], msg.sender, amount[i]);
        }
    }
}
