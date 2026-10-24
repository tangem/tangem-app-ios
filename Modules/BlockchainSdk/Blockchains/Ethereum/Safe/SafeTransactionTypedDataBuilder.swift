//
//  SafeTransactionTypedDataBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension SafeTransaction {
    func signHash(chainId: Int, safeAddress: String) -> Data {
        typedData(chainId: chainId, safeAddress: safeAddress).signHash
    }

    func typedData(chainId: Int, safeAddress: String) -> EIP712TypedData {
        SafeTransactionTypedDataBuilder().makeTypedData(safeTransaction: self, chainId: chainId, safeAddress: safeAddress)
    }
}

/// Lays a Safe transaction out as the EIP-712 message its signature covers: the `SafeTx` struct under the domain of
/// `{chainId, verifyingContract}` the Safe contracts have used since 1.3.0.
struct SafeTransactionTypedDataBuilder {
    func makeTypedData(safeTransaction: SafeTransaction, chainId: Int, safeAddress: String) -> EIP712TypedData {
        let types: [String: [EIP712Type]] = [
            Constants.domainType: [
                .init(name: "chainId", type: "uint256"),
                .init(name: "verifyingContract", type: "address"),
            ],
            Constants.primaryType: [
                .init(name: "to", type: "address"),
                .init(name: "value", type: "uint256"),
                .init(name: "data", type: "bytes"),
                .init(name: "operation", type: "uint8"),
                .init(name: "safeTxGas", type: "uint256"),
                .init(name: "baseGas", type: "uint256"),
                .init(name: "gasPrice", type: "uint256"),
                .init(name: "gasToken", type: "address"),
                .init(name: "refundReceiver", type: "address"),
                .init(name: "nonce", type: "uint256"),
            ],
        ]

        let domain: JSON = .object([
            "chainId": .number(chainId),
            "verifyingContract": .string(safeAddress),
        ])

        // `uint256` values travel as decimal strings, which the encoder reads through `BigUInt`
        let message: JSON = .object([
            "to": .string(safeTransaction.to),
            "value": .string(safeTransaction.value.description),
            "data": .string(safeTransaction.data.hex().addHexPrefix()),
            "operation": .number(safeTransaction.operation),
            "safeTxGas": .string(safeTransaction.safeTxGas.description),
            "baseGas": .string(safeTransaction.baseGas.description),
            "gasPrice": .string(safeTransaction.gasPrice.description),
            "gasToken": .string(safeTransaction.gasToken),
            "refundReceiver": .string(safeTransaction.refundReceiver),
            "nonce": .number(safeTransaction.nonce),
        ])

        return EIP712TypedData(types: types, primaryType: Constants.primaryType, domain: domain, message: message)
    }
}

// MARK: - Constants

private extension SafeTransactionTypedDataBuilder {
    enum Constants {
        static let domainType = "EIP712Domain"
        static let primaryType = "SafeTx"
    }
}
