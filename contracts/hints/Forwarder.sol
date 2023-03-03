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

// @optimization using list of struct
contract Forwarder {
    struct PaymentInput {
        address payer;
        uint256 amount;
        uint256 deadline;
        address _token;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// Batch signature and transfer
    function payViaSignature(PaymentInput[] calldata paymentInputs) external {
        for (uint i = 0; i < paymentInputs.length; ) {
            PaymentInput memory paymentInput = paymentInputs[i];

            IToken token = IToken(paymentInput._token);
            token.permit(
                paymentInput.payer,
                address(this),
                paymentInput.amount,
                paymentInput.deadline,
                paymentInput.v,
                paymentInput.r,
                paymentInput.s
            );
            token.transferFrom(
                paymentInput.payer,
                msg.sender,
                paymentInput.amount
            );
            // @optimization using unchecked in loop
            unchecked {
                i++;
            }
        }
    }
}
