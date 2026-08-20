//
//  PolymarketClobAuth.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.EIP712TypedData
import struct BlockchainSdk.EIP712Type
import enum BlockchainSdk.JSON

public enum PolymarketClobAuth {
    public static let nonce = "0"

    public static func digest(ownerAddress: String, timestamp: String) -> Data {
        makeTypedData(ownerAddress: ownerAddress, timestamp: timestamp).signHash
    }
}

// MARK: - Private implementation

private extension PolymarketClobAuth {
    static func makeTypedData(ownerAddress: String, timestamp: String) -> EIP712TypedData {
        let types: [String: [EIP712Type]] = [
            "EIP712Domain": [
                .init(name: "name", type: "string"),
                .init(name: "version", type: "string"),
                .init(name: "chainId", type: "uint256"),
            ],
            primaryType: [
                .init(name: "address", type: "address"),
                .init(name: "timestamp", type: "string"),
                .init(name: "nonce", type: "uint256"),
                .init(name: "message", type: "string"),
            ],
        ]

        let domain: JSON = .object([
            "name": .string(domainName),
            "version": .string(domainVersion),
            "chainId": .number(chainId),
        ])

        let message: JSON = .object([
            "address": .string(ownerAddress),
            "timestamp": .string(timestamp),
            "nonce": .string(nonce),
            "message": .string(attestation),
        ])

        return EIP712TypedData(types: types, primaryType: primaryType, domain: domain, message: message)
    }

    static let domainName = "ClobAuthDomain"
    static let domainVersion = "1"
    static let chainId = 137
    static let primaryType = "ClobAuth"
    static let attestation = "This message attests that I control the given wallet"
}
