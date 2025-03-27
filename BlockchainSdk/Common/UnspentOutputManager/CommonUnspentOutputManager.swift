//
//  CommonUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

class CommonUnspentOutputManager {
    private var outputs: ThreadSafeContainer<[UTXOLockingScript: [UnspentOutput]]> = [:]

    private let address: any Address
    private let preImageTransactionBuilder: UTXOPreImageTransactionBuilder
    private let lockingScriptBuilder: LockingScriptBuilder

    init(
        address: any Address,
        preImageTransactionBuilder: UTXOPreImageTransactionBuilder,
        lockingScriptBuilder: LockingScriptBuilder
    ) {
        self.address = address
        self.preImageTransactionBuilder = preImageTransactionBuilder
        self.lockingScriptBuilder = lockingScriptBuilder
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

    func preImage(amount: UInt64, fee: UInt64, destination: String) throws -> PreImageTransaction {
        try preImage(amount: amount, fee: .exactly(fee: fee), destination: destination)
    }

    func preImage(amount: UInt64, feeRate: UInt64, destination: String) throws -> PreImageTransaction {
        try preImage(amount: amount, fee: .calculate(feeRate: feeRate), destination: destination)
    }

    func allOutputs() -> [ScriptUnspentOutput] {
        outputs.read().flatMap { key, value in
            value.map { ScriptUnspentOutput(output: $0, script: key) }
        }
    }

    func confirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { $0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }

    func unconfirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { !$0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Private

private extension CommonUnspentOutputManager {
    func preImage(amount: UInt64, fee: UTXOPreImageTransactionBuilderFee, destination: String) throws -> PreImageTransaction {
        let changeScript = try lockingScriptBuilder.lockingScript(for: address)
        let destinationScript = try lockingScriptBuilder.lockingScript(for: destination)

        let preImage = try preImageTransactionBuilder.preImage(
            outputs: allOutputs(),
            changeScript: changeScript.type,
            destination: .init(amount: amount, script: destinationScript.type),
            fee: fee
        )

        // Check fee rate to exclude too big fee
        assert(preImage.fee / UInt64(preImage.size) < 1_000, "Fee is too large")

        var outputs: [PreImageTransaction.OutputType] = [
            .destination(destinationScript, value: preImage.destination),
        ]

        if preImage.change > .zero {
            outputs.append(.change(changeScript, value: preImage.change))
        }

        let preImageTransaction = PreImageTransaction(inputs: preImage.outputs, outputs: outputs, fee: preImage.fee)

        assert(!preImageTransaction.inputs.isEmpty, "Inputs has to have at least one UTXO")
        assert(!preImageTransaction.outputs.isEmpty, "Outputs has to have at least destination output")

        return preImageTransaction
    }
}
