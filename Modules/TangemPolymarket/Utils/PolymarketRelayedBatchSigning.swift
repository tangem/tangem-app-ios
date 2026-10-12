//
//  PolymarketRelayedBatchSigning.swift
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

public enum PolymarketRelayedBatchSigning {
    public static func digest(for approvals: PolymarketRelayedBatch.Unsigned) throws(PolymarketRelayedBatchSigningError) -> Data {
        guard approvals.depositWalletAddress.isEvmAddress else {
            throw .invalidDepositWalletAddress
        }

        guard approvals.nonce.isUnsignedInteger else {
            throw .invalidNonce
        }

        guard approvals.deadline.isUnsignedInteger else {
            throw .invalidDeadline
        }

        return makeTypedData(for: approvals).signHash
    }
}

// MARK: - Private implementation

private extension String {
    var isUnsignedInteger: Bool {
        guard !isEmpty, allSatisfy(\.isASCIINumber) else {
            return false
        }

        let digits = drop { $0 == "0" }

        guard digits.count == Constants.maxUint256.count else {
            return digits.count < Constants.maxUint256.count
        }

        return !Constants.maxUint256.lexicographicallyPrecedes(digits)
    }

    enum Constants {
        static let maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    }
}

private extension Character {
    var isASCIINumber: Bool {
        isASCII && isNumber
    }
}

private extension PolymarketRelayedBatchSigning {
    static func makeTypedData(for approvals: PolymarketRelayedBatch.Unsigned) -> EIP712TypedData {
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
            "verifyingContract": .string(approvals.depositWalletAddress),
        ])

        let message: JSON = .object([
            "wallet": .string(approvals.depositWalletAddress),
            "nonce": .string(approvals.nonce),
            "deadline": .string(approvals.deadline),
            "calls": .array(approvals.calls.map { call in
                .object([
                    "target": .string(call.target),
                    "value": .string(call.value),
                    "data": .string(call.data),
                ])
            }),
        ])

        return EIP712TypedData(types: types, primaryType: primaryType, domain: domain, message: message)
    }

    static let domainName = PolymarketDepositWalletDomain.name
    static let domainVersion = PolymarketDepositWalletDomain.version
    static let chainId = PolymarketChain.polygonId
    static let primaryType = "Batch"
    static let callType = "Call"
}
