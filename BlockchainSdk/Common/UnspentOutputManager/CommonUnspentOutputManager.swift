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
    private let preImageTransactionBuilder: UTXOPreImageTransactionBuilder
    private let lockingScriptBuilder: LockingScriptBuilder

    init(preImageTransactionBuilder: UTXOPreImageTransactionBuilder, lockingScriptBuilder: LockingScriptBuilder) {
        self.preImageTransactionBuilder = preImageTransactionBuilder
        self.lockingScriptBuilder = lockingScriptBuilder
    }
}

// MARK: - UnspentOutputManager

extension CommonUnspentOutputManager: UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: UTXOLockingScript) {
        self.outputs.mutate { $0[script] = outputs }
    }

    func allOutputs() -> [ScriptUnspentOutput] {
        outputs.read().flatMap { key, value in
            value.map { ScriptUnspentOutput(output: $0, script: key) }
        }
    }

    func preImage(amount: UInt64, fee: UInt64, destination: String) throws -> UTXOPreImageTransactionBuilderTransaction {
        let destinationScript = try lockingScriptBuilder.lockingScript(for: destination)
        let preImage = try preImageTransactionBuilder.preImage(
            outputs: allOutputs(),
            amount: amount,
            fee: .exactly(fee: fee),
            destinationScript: destinationScript.type
        )

        return preImage
    }

    func preImage(amount: UInt64, feeRate: UInt64, destination: String) throws -> UTXOPreImageTransactionBuilderTransaction {
        let destinationScript = try lockingScriptBuilder.lockingScript(for: destination)
        let preImage = try preImageTransactionBuilder.preImage(
            outputs: allOutputs(),
            amount: amount,
            fee: .calculate(feeRate: feeRate),
            destinationScript: destinationScript.type
        )

        return preImage
    }
}
