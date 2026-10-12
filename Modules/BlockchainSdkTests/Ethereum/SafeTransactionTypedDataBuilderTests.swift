//
//  SafeTransactionTypedDataBuilderTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift
@testable import BlockchainSdk
import Testing

struct SafeTransactionTypedDataBuilderTests {
    private let builder = SafeTransactionTypedDataBuilder()

    @Test("The struct hashes to the SafeTx type hash the contracts compile in")
    func safeTxTypeHash() {
        let typedData = builder.makeTypedData(safeTransaction: Constants.transaction, chainId: 1, safeAddress: Constants.safeAddress)

        #expect(typedData.typeHash.hex() == "bb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8")
    }

    @Test("The domain names only the chain and the contract")
    func domainTypeHash() {
        let typedData = builder.makeTypedData(safeTransaction: Constants.transaction, chainId: 1, safeAddress: Constants.safeAddress)
        let domainTypeHash = typedData.makeTypeData(primaryType: "EIP712Domain").sha3(.keccak256)

        #expect(domainTypeHash.hex() == "47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218")
    }

    @Test("The nonce and the chain are both part of the digest")
    func digestChangesWithNonceAndChain() {
        let base = builder.makeTypedData(safeTransaction: Constants.transaction, chainId: 1, safeAddress: Constants.safeAddress).signHash
        let otherNonce = builder.makeTypedData(safeTransaction: Constants.transaction(nonce: 8), chainId: 1, safeAddress: Constants.safeAddress).signHash
        let otherChain = builder.makeTypedData(safeTransaction: Constants.transaction, chainId: 137, safeAddress: Constants.safeAddress).signHash

        #expect(base.count == 32)
        #expect(base != otherNonce)
        #expect(base != otherChain)
    }
}

// MARK: - Constants

private extension SafeTransactionTypedDataBuilderTests {
    enum Constants {
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let transaction = transaction(nonce: 7)

        static func transaction(nonce: Int) -> SafeTransaction {
            SafeTransaction(
                to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                value: BigUInt(1_000_000_000_000_000),
                data: Data(),
                operation: 0,
                safeTxGas: BigUInt(21_000),
                baseGas: BigUInt(100_000),
                gasPrice: BigUInt(1_500_000_000),
                gasToken: "0x0000000000000000000000000000000000000000",
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                nonce: nonce
            )
        }
    }
}
