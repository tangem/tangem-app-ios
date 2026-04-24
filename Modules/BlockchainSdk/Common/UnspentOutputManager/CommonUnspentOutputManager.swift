//
//  CommonUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

class CommonUnspentOutputManager {
    private var outputs: ThreadSafeContainer<[UTXOLockingScript: [UnspentOutput]]> = [:]

    private let preImageTransactionBuilder: UTXOPreImageTransactionBuilder
    private let lockingScriptBuilder: LockingScriptBuilder
    private let sorter: UTXOTransactionInputsSorter

    init(
        preImageTransactionBuilder: UTXOPreImageTransactionBuilder,
        sorter: UTXOTransactionInputsSorter,
        lockingScriptBuilder: LockingScriptBuilder
    ) {
        self.preImageTransactionBuilder = preImageTransactionBuilder
        self.sorter = sorter
        self.lockingScriptBuilder = lockingScriptBuilder
    }

    /// Will be overridden in KaspaUnspentOutputManager
    func availableOutputs() -> [ScriptUnspentOutput] {
        outputs.read().flatMap { key, value in
            value.filter { $0.isConfirmed }.map { ScriptUnspentOutput(output: $0, script: key) }
        }
    }
}

// MARK: - UnspentOutputManager

extension CommonUnspentOutputManager: UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: String) throws {
        let script = try lockingScriptBuilder.lockingScript(for: address)
        self.outputs.mutate { $0[script] = outputs }
    }

    func update(outputs: [UnspentOutput], for script: UTXOLockingScript) {
        self.outputs.mutate { $0[script] = outputs }
    }

    func preImage(amount: Int, fee: Int, destination: String, changeAddress: String, opReturn: Data?) async throws -> PreImageTransaction {
        assert(fee > 0, "Fee can't be zero")

        return try await preImage(amount: amount, fee: .exactly(fee: fee), destination: destination, changeAddress: changeAddress, opReturn: opReturn)
    }

    func preImage(amount: Int, feeRate: Int, destination: String, changeAddress: String, opReturn: Data?) async throws -> PreImageTransaction {
        assert(feeRate > 0, "FeeRate can't be zero")

        return try await preImage(amount: amount, fee: .calculate(feeRate: feeRate), destination: destination, changeAddress: changeAddress, opReturn: opReturn)
    }

    func confirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { $0.isConfirmed }.sum(by: \.amount)
    }

    func unconfirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { !$0.isConfirmed }.sum(by: \.amount)
    }

    func clearOutputs() {
        outputs.mutate { $0.removeAll() }
    }
}

// MARK: - Private

private extension CommonUnspentOutputManager {
    func preImage(amount: Int, fee: UTXOPreImageTransactionBuilderFee, destination: String, changeAddress: String, opReturn: Data?) async throws -> PreImageTransaction {
        let changeScript = try lockingScriptBuilder.lockingScript(for: changeAddress)
        let destinationScript = try lockingScriptBuilder.lockingScript(for: destination)

        let preImage = try await preImageTransactionBuilder.preImage(
            outputs: availableOutputs(),
            changeScript: changeScript.type,
            destination: .init(amount: amount, script: destinationScript.type),
            fee: fee
        )

        let inputs = sorter.sort(inputs: preImage.outputs)

        // Check fee rate to exclude too big fee
        var outputs: [PreImageTransaction.OutputType] = [
            .destination(destinationScript, value: preImage.destination),
        ]

        if preImage.change > 0 {
            outputs.append(.change(changeScript, value: preImage.change))
        }

        let preImageTransaction = PreImageTransaction(inputs: inputs, outputs: outputs, fee: preImage.fee, opReturn: opReturn)

        assert(!preImageTransaction.inputs.isEmpty, "Inputs has to have at least one UTXO")
        assert(!preImageTransaction.outputs.isEmpty, "Outputs has to have at least destination output")

        return preImageTransaction
    }
}
