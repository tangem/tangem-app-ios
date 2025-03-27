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
    private let lockingScriptBuilder: LockingScriptBuilder

    init(
        address: any Address,
        lockingScriptBuilder: LockingScriptBuilder
    ) {
        self.address = address
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
