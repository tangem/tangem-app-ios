//
//  CommonUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

class CommonUnspentOutputManager {
    private let scriptBuilder: LockingScriptBuilder
    private var outputs: ThreadSafeContainer<[Data: [UnspentOutput]]> = [:]

    init(scriptBuilder: LockingScriptBuilder) {
        self.scriptBuilder = scriptBuilder
    }
}

extension CommonUnspentOutputManager: UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: String) {
        do {
            let script = try scriptBuilder.lockingScript(for: address)
            self.outputs.mutate { $0[script] = outputs }
        } catch {
            BSDKLogger.error("lockingScript build error", error: error)
        }
    }

    func preImage(amount: UInt64, fee: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction {
        try UTXOPreImageTransactionBuilder(
            outputs: allOutputs(),
            amount: amount,
            fee: .exactly(fee: fee),
            changeScript: .p2wpkh,
            destinationScript: .p2wpkh,
            dustThreshold: 10_000
        ).preImage()
    }

    func preImage(amount: UInt64, feeRate: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction {
        try UTXOPreImageTransactionBuilder(
            outputs: allOutputs(),
            amount: amount,
            fee: .calculate(feeRate: feeRate),
            changeScript: .p2wpkh,
            destinationScript: .p2wpkh,
            dustThreshold: 10_000
        ).preImage()
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

extension CommonUnspentOutputManager {
    enum Errors: LocalizedError {
        case noOutputs

        var errorDescription: String? {
            switch self {
            case .noOutputs:
                return "No outputs"
            }
        }
    }
}
