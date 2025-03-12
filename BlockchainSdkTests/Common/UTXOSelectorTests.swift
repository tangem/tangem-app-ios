//
//  UTXOSelectorTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
import XCTest
@testable import BlockchainSdk

class UTXOSelectorTests {
    @Test
    func testCalculationFee() throws {
        // given
        let selector = UTXOSelector()
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // when
        // Try to select amount which sum of 2 outputs
        let selected = try selector.select(
            outputs: outputs,
            amount: 300_000, // 0.0003 BTC
            fee: .calculate(feeRate: 10)
        )

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee > 0) // some estimated fee
        #expect(selected.change < 500_000 + 300_000) // output - fee - amount
    }

    @Test
    func testExactlyFee() throws {
        // given
        let selector = UTXOSelector()
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // when
        let selected = try selector.select(
            outputs: outputs,
            amount: 300_000, // 0.0003 BTC
            fee: .exactly(fee: 100_000) // 0.0001 BTC
        )

        // then
        #expect(selected.outputs.count == 1) // 0.0005
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.change == 100_000) // 500_000 - fee - 300_000
    }

    @Test
    func testExactlyNoChangeFee() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let selector = UTXOSelector(dustThreshold: dust)
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // when
        let selected = try selector.select(
            outputs: outputs,
            amount: 400_000, // 0.0004 BTC
            fee: .exactly(fee: 100_000) // 0.0001 BTC
        )

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.change == 0) // 500_000 - 400_000 - 100_000 (output - fee - amount)
    }

    @Test
    func testCalculationNoChangeFee() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let selector = UTXOSelector(dustThreshold: dust)
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // when
        let selected = try selector.select(
            outputs: outputs,
            amount: 400_000, // 0.0004 BTC
            fee: .calculate(feeRate: 10)
        )

        // then
        #expect(selected.outputs.count == 1) // 500_000

        // estimated fee == dust if change < dust.
        // We will not add change and spend full utxo like `estimated fee = (some fee + change))`
        #expect(selected.fee > 0)
        #expect(selected.change == 0) // 500_000 - 400_000 - 100_000 (output - amount - fee)
    }

    @Test
    func testThrowsInsufficientFunds() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let selector = UTXOSelector(dustThreshold: dust)
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // then
        #expect(throws: UTXOSelector.Error.insufficientFunds.self) {
            let selected = try selector.select(
                outputs: outputs,
                amount: 900_000, // 0.0004 BTC
                fee: .calculate(feeRate: 10)
            )
        }
    }

    @Test
    func testThrowsInsufficientFundsForFee() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let selector = UTXOSelector(dustThreshold: dust)
        let outputs = [
            UnspentOutput(blockId: 0, hash: Data(), index: 0, amount: 100_000), // 0.0001 BTC
            UnspentOutput(blockId: 1, hash: Data(), index: 0, amount: 200_000), // 0.0002 BTC
            UnspentOutput(blockId: 2, hash: Data(), index: 0, amount: 500_000), // 0.0005 BTC
        ]

        // then
        #expect(throws: UTXOSelector.Error.insufficientFundsForFee.self) {
            let selected = try selector.select(
                outputs: outputs,
                amount: 800_000,
                fee: .calculate(feeRate: 10)
            )
        }

        #expect(throws: UTXOSelector.Error.insufficientFundsForFee.self) {
            let selected = try selector.select(
                outputs: outputs,
                amount: 700_000,
                fee: .exactly(fee: 110_000)
            )
        }
    }
}
