//
//  TransactionParamsBuilderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Stellar memo built from the entered extra id")
struct TransactionParamsBuilderTests {
    @Test("A number in its plain form is sent as a memo id", arguments: [
        ("123", UInt64(123)),
        ("0", UInt64(0)),
        ("18446744073709551615", UInt64.max),
    ])
    func plainNumberIsSentAsID(value: String, expectedID: UInt64) throws {
        guard case .id(let memoID)? = try makeStellarMemo(value: value) else {
            Issue.record("Expected MEMO_ID for \(value)")
            return
        }

        #expect(memoID == expectedID)
    }

    @Test("A string that is not a number in its plain form is sent as text unchanged", arguments: [
        "00123",
        "+123",
        " 123",
        "18446744073709551616",
        "abc",
        String(repeating: "a", count: 28),
    ])
    func nonPlainNumberIsSentAsText(value: String) throws {
        guard case .text(let text)? = try makeStellarMemo(value: value) else {
            Issue.record("Expected MEMO_TEXT for \(value)")
            return
        }

        #expect(text == value)
    }

    @Test("A text memo longer than 28 bytes is rejected", arguments: [
        String(repeating: "a", count: 29),
        String(repeating: "é", count: 15),
    ])
    func textOverByteLimitIsRejected(value: String) {
        #expect(throws: TransactionParamsBuilderError.invalidMemoDestinationTag) {
            _ = try makeStellarMemo(value: value)
        }
    }
}

// MARK: - Helpers

private extension TransactionParamsBuilderTests {
    func makeStellarMemo(value: String) throws -> StellarMemo? {
        let builder = TransactionParamsBuilder(blockchain: .stellar(curve: .ed25519, testnet: false))
        let params = try #require(try builder.transactionParameters(value: value) as? StellarTransactionParams)
        return params.memo
    }
}
