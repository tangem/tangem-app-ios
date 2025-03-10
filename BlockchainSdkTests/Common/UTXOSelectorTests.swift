//
//  UTXOSelectorTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

class UTXOSelectorTests: XCTestCase {
    func testUTXOSelectionWithDustChange() throws {
        let selector = UTXOSelector(dustThreshold: 1000)
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 1000),
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 2000),
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 5000),
        ]
        let targetAmount: UInt64 = 2500
        let selected = try selector.select(outputs: outputs, amount: targetAmount, feeRate: 10, algorithm: .bnb)

        XCTAssertEqual(selected.count, 1)
    }

    func testUTXOSelectionWithValidChange() throws {
        let selector = UTXOSelector()
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 10000),
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 5000),
        ]

        let targetAmount: UInt64 = 3000
        let selected = try selector.select(outputs: outputs, amount: targetAmount, feeRate: 10)

        XCTAssertEqual(selected.count, 1)
    }

    func testUTXOSelectionWithFullSpendOneOutput() throws {
        let selector = UTXOSelector()
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 10000),
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 5000),
        ]

        let targetAmount: UInt64 = 10000
        let selected = try selector.select(outputs: outputs, amount: targetAmount, feeRate: 10)

        // Should be 2 output. One to send, second to cover fee
        XCTAssertEqual(selected.count, 2)
    }

    func testUTXOSelectionWithFullSpendOneOutput() throws {
        let selector = UTXOSelector()
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 10000),
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 5000),
        ]

        let targetAmount: UInt64 = 15000
        let selected = try selector.select(outputs: outputs, amount: targetAmount, feeRate: 10)

        // Should be 2 output. One to send, second to cover fee
        XCTAssertEqual(selected.count, 2)
    }
}
