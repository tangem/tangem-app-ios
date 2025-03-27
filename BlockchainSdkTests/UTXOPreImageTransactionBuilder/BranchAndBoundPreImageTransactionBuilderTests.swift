//
//  BranchAndBoundPreImageTransactionBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class BranchAndBoundPreImageTransactionBuilderTests {
    private let script: UTXOLockingScript = .init(data: Data(hexString: ""), type: .p2wpkh)
    private lazy var outputs: [ScriptUnspentOutput] = [
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 0, txId: "", index: 0, amount: 100_000), // 0.0001 BTC
            script: script
        ),
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 1, txId: "", index: 0, amount: 200_000), // 0.0002 BTC
            script: script
        ),
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 2, txId: "", index: 0, amount: 500_000), // 0.0005 BTC
            script: script
        ),
    ]

    @Test
    func testCalculationFee() throws {
        // given
        let size: UInt64 = 5_000
        let feeRate: UInt64 = 10
        let expectedFee = size * feeRate
        let calculator = TestCalculator(size: size)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try selector.preImage(outputs: outputs, changeScript: .p2wpkh, destination: .init(amount: 300_000, script: .p2wpkh), fee: .calculate(feeRate: feeRate))

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee == expectedFee) // some estimated fee
        #expect(selected.destination == 300_000)
        #expect(selected.change == 500_000 - 300_000 - expectedFee) // output - amount - fee
    }

    @Test
    func testExactlyFee() throws {
        // given
        let calculator = TestCalculator()
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try selector.preImage(outputs: outputs, changeScript: .p2wpkh, destination: .init(amount: 300_000, script: .p2wpkh), fee: .exactly(fee: 100_000))

        // then
        #expect(selected.outputs.count == 1) // 0.0005
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.destination == 300_000)
        #expect(selected.change == 100_000) // 500_000 - fee - 300_000
    }

    @Test
    func testExactlyNoChangeFee() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let calculator = TestCalculator(dust: dust)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try selector.preImage(outputs: outputs, changeScript: .p2wpkh, destination: .init(amount: 400_000, script: .p2wpkh), fee: .exactly(fee: 100_000))

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.destination == 400_000)
        #expect(selected.change == 0) // 500_000 - 400_000 - 100_000 (output - fee - amount)
    }

    @Test
    func testCalculationNoChangeFee() throws {
        // given
        let size: UInt64 = 5_000
        let dust: UInt64 = 100_000 // Big dust
        let feeRate: UInt64 = 10
        let expectedFee = size * feeRate
        let calculator = TestCalculator(dust: dust, size: size)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try selector.preImage(outputs: outputs, changeScript: .p2wpkh, destination: .init(amount: 400_000, script: .p2wpkh), fee: .calculate(feeRate: feeRate))

        // then
        #expect(selected.outputs.count == 1) // 500_000

        // estimated fee == dust if change < dust.
        // We will not add change and spend full utxo like `estimated fee = (some fee + change))`
        #expect(selected.fee == expectedFee)
        #expect(selected.destination == 500_000 - expectedFee) // 500_000(full unspent) - fee
        #expect(selected.change == 0) // 500_000 - 400_000 - 100_000 (output - amount - fee)
    }

    @Test
    func testThrowsInsufficientFunds() throws {
        // given
        let dust: UInt64 = 100_000 // Big dust
        let calculator = TestCalculator(dust: dust)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // then
        #expect(throws: UTXOPreImageTransactionBuilderError.insufficientFunds) {
            try selector.preImage(outputs: outputs, changeScript: .p2wpkh, destination: .init(amount: 900_000, script: .p2wpkh), fee: .calculate(feeRate: 10))
        }
    }
}

extension BranchAndBoundPreImageTransactionBuilderTests {
    struct TestCalculator: UTXOTransactionSizeCalculator {
        private let dust: UInt64
        private let size: UInt64

        init(dust: UInt64 = 10_000, size: UInt64 = 10_000) {
            self.dust = dust
            self.size = size
        }

        func dust(type: UTXOScriptType) -> Int { Int(dust) }
        func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) -> Int { Int(size) }
    }
}
