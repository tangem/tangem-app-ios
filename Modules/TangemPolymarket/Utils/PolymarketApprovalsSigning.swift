//
//  PolymarketApprovalsSigning.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct BlockchainSdk.EIP712TypedData
import struct BlockchainSdk.EIP712Type
import enum BlockchainSdk.JSON

public enum PolymarketApprovalsSigning {
    /// The EIP-712 encoder skips a field it cannot parse instead of failing, so an unchecked malformed
    /// address would drop out of the signed structure and the card would sign the wrong payload.
    public static func digest(
        depositWalletAddress: String,
        nonce: String,
        deadline: String,
        calls: [PolymarketApprovalsBatch.Call]
    ) throws(PolymarketApprovalsSigningError) -> Data {
        guard depositWalletAddress.isEvmAddress else {
            throw .invalidDepositWalletAddress
        }

        return makeTypedData(
            depositWalletAddress: depositWalletAddress,
            nonce: nonce,
            deadline: deadline,
            calls: calls
        ).signHash
    }
}

// MARK: - Private implementation

private extension PolymarketApprovalsSigning {
    static func makeTypedData(
        depositWalletAddress: String,
        nonce: String,
        deadline: String,
        calls: [PolymarketApprovalsBatch.Call]
    ) -> EIP712TypedData {
        let types: [String: [EIP712Type]] = [
            "EIP712Domain": [
                .init(name: "name", type: "string"),
                .init(name: "version", type: "string"),
                .init(name: "chainId", type: "uint256"),
                .init(name: "verifyingContract", type: "address"),
            ],
            primaryType: [
                .init(name: "wallet", type: "address"),
                .init(name: "nonce", type: "uint256"),
                .init(name: "deadline", type: "uint256"),
                .init(name: "calls", type: "Call[]"),
            ],
            callType: [
                .init(name: "target", type: "address"),
                .init(name: "value", type: "uint256"),
                .init(name: "data", type: "bytes"),
            ],
        ]

        let domain: JSON = .object([
            "name": .string(domainName),
            "version": .string(domainVersion),
            "chainId": .number(chainId),
            "verifyingContract": .string(depositWalletAddress),
        ])

        let message: JSON = .object([
            "wallet": .string(depositWalletAddress),
            "nonce": .string(nonce),
            "deadline": .string(deadline),
            "calls": .array(calls.map { call in
                .object([
                    "target": .string(call.target),
                    "value": .string(call.value),
                    "data": .string(call.data),
                ])
            }),
        ])

        return EIP712TypedData(types: types, primaryType: primaryType, domain: domain, message: message)
    }

    static let domainName = "DepositWallet"
    static let domainVersion = "1"
    static let chainId = 137
    static let primaryType = "Batch"
    static let callType = "Call"
}
