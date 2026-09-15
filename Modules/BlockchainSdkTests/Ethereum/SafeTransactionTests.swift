//
//  SafeTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk
import Testing

struct SafeTransactionTests {
    @Test("The fee is the whole gas allowance at the signed price")
    func fee() {
        let transaction = SafeTransaction(
            to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
            value: 0,
            data: Data(),
            operation: 0,
            safeTxGas: 23_520,
            baseGas: 110_000,
            gasPrice: 1_500_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: "0x0000000000000000000000000000000000000000",
            nonce: 7
        )

        #expect(transaction.fee == BigUInt(133_520) * 1_500_000_000)
    }
}
