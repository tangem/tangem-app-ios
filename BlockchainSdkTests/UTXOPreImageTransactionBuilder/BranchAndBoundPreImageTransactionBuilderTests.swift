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
    private let script: UTXOLockingScript = .init(data: Data(), type: .p2wpkh, spendable: .publicKey(Keys.Secp256k1.publicKey))
    private lazy var outputs: [ScriptUnspentOutput] = [
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 1, txId: "", index: 0, amount: 100_000), // 0.0001 BTC
            script: script
        ),
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 2, txId: "", index: 0, amount: 200_000), // 0.0002 BTC
            script: script
        ),
        ScriptUnspentOutput(
            output: UnspentOutput(blockId: 3, txId: "", index: 0, amount: 500_000), // 0.0005 BTC
            script: script
        ),
    ]
    private lazy var singleOutput: [ScriptUnspentOutput] = [
        .init(
            output: .init(
                blockId: 1,
                txId: "",
                index: 0,
                amount: 12_157_434_110
            ),
            script: script
        ),
    ]

    @Test
    func testTaskCancel() async throws {
        let calculator = CommonUTXOTransactionSizeCalculator(network: BitcoinNetworkParams())
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        let task = Task {
            await #expect(throws: CancellationError.self) {
                _ = try await selector.preImage(
                    outputs: self.outputs,
                    changeScript: .p2pkh,
                    destination: .init(amount: 100_000, script: .p2pkh),
                    fee: .calculate(feeRate: 1)
                )
            }
        }

        task.cancel()
        // Wait the task async context
        _ = await task.value
    }

    @Test
    func testManyOutputs() async throws {
        // given
        let outputs: [ScriptUnspentOutput] = (1 ... 1000).map { i in
            .init(output: UnspentOutput(blockId: i, txId: "", index: 0, amount: UInt64(i) * 1_000), script: script)
        }

        let feeRate = 10
        let expectedFee = 1430
        let calculator = CommonUTXOTransactionSizeCalculator(network: BitcoinNetworkParams())
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2wpkh,
            destination: .init(amount: 300_000, script: .p2wpkh),
            fee: .calculate(feeRate: feeRate)
        )

        // then
        #expect(selected.outputs.count == 1)
        #expect(selected.fee == expectedFee)
        #expect(selected.destination == 300_000)
        #expect(selected.change == 570)
    }

    @Test
    func testCalculationFee() async throws {
        // given
        let size = 5_000
        let feeRate = 10
        let expectedFee = size * feeRate
        let calculator = TestCalculator(size: size)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2wpkh,
            destination: .init(amount: 300_000, script: .p2wpkh),
            fee: .calculate(feeRate: feeRate)
        )

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee == expectedFee)
        #expect(selected.destination == 300_000)
        #expect(selected.change == 500_000 - 300_000 - expectedFee) // output - amount - fee
    }

    @Test
    func testExactlyFee() async throws {
        // given
        let calculator = TestCalculator()
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2wpkh,
            destination: .init(amount: 300_000, script: .p2wpkh),
            fee: .exactly(fee: 100_000)
        )

        // then
        #expect(selected.outputs.count == 1) // 0.0005
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.destination == 300_000)
        #expect(selected.change == 100_000) // 500_000 - fee - 300_000
    }

    @Test
    func testExactlyNoChangeFee() async throws {
        // given
        let dust = 100_000 // Big dust
        let calculator = TestCalculator(dust: dust)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2wpkh,
            destination: .init(amount: 400_000, script: .p2wpkh),
            fee: .exactly(fee: 100_000)
        )

        // then
        #expect(selected.outputs.count == 1) // 500_000
        #expect(selected.fee == 100_000) // exactly fee
        #expect(selected.destination == 400_000)
        #expect(selected.change == 0) // 500_000 - 400_000 - 100_000 (output - fee - amount)
    }

    @Test
    func testCalculationNoChangeFee() async throws {
        // given
        let size = 5_000
        let dust = 100_000 // Big dust
        let feeRate = 10
        let expectedFee = size * feeRate
        let calculator = TestCalculator(dust: dust, size: size)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2wpkh,
            destination: .init(amount: 400_000, script: .p2wpkh),
            fee: .calculate(feeRate: feeRate)
        )

        // then
        #expect(selected.outputs.count == 2) // 500_000 + 100_000

        // estimated fee == dust if change < dust.
        // We will not add change and spend full utxo like `estimated fee = (some fee + change))`
        #expect(selected.fee == expectedFee)
        #expect(selected.destination == 400_000) // 500_000(full unspent) - fee
        #expect(selected.change == 150_000) // 500_000 - 400_000 - 100_000 (output - amount - fee)
    }

    @Test
    func testCalculationFeeSingleInputNearFullAmountReturnsValidPreImage() async throws {
        // given
        let calculator = TestCalculator(dust: 546, size: 192)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // when
        let selected = try await selector.preImage(
            outputs: singleOutput,
            changeScript: .p2pkh,
            destination: .init(amount: 12_157_300_000, script: .p2pkh),
            fee: .calculate(feeRate: 977)
        )

        // then
        #expect(selected.outputs.count == 1)
        #expect(selected.destination == 12_157_300_000)
    }

    @Test
    func testCalculationFeeMultipleInputsNearFullAmountReturnsValidPreImage() async throws {
        // given
        let calculator = TestCalculator(dust: 546, size: 192)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)
        let expectedFee = 192 * 100

        // when
        let selected = try await selector.preImage(
            outputs: outputs,
            changeScript: .p2pkh,
            destination: .init(amount: 790_000, script: .p2pkh),
            fee: .calculate(feeRate: 100)
        )

        // then
        #expect(selected.outputs.count == 3)
        #expect(selected.destination == 790_000)
        #expect(selected.fee == expectedFee)
        #expect(selected.change == (100_000 + 200_000 + 500_000) - 790_000 - expectedFee)
    }

    @Test
    func testThrowsInsufficientFunds() async throws {
        // given
        let dust = 100_000 // Big dust
        let calculator = TestCalculator(dust: dust)
        let selector = BranchAndBoundPreImageTransactionBuilder(calculator: calculator)

        // then
        await #expect(throws: UTXOPreImageTransactionBuilderError.insufficientFunds) {
            try await selector.preImage(
                outputs: self.outputs,
                changeScript: .p2wpkh,
                destination: .init(amount: 900_000, script: .p2wpkh),
                fee: .calculate(feeRate: 10)
            )
        }
    }
}

extension BranchAndBoundPreImageTransactionBuilderTests {
    struct TestCalculator: UTXOTransactionSizeCalculator {
        private let dust: Int
        private let size: Int

        init(dust: Int = 10_000, size: Int = 10_000) {
            self.dust = dust
            self.size = size
        }

        func dust(type: UTXOScriptType) -> Int { dust }
        func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) -> Int { size }
    }
}
