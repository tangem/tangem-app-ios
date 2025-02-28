//
//  CommonUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

class CommonUnspentOutputManager {
    private var outputs: ThreadSafeContainer<[Data: [UnspentOutput]]> = [:]
}

extension CommonUnspentOutputManager: UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: Data) {
        self.outputs.mutate { $0[script] = outputs }
    }

    func allOutputs() -> [ScriptUnspentOutput] {
        outputs.read().flatMap { key, value in
            value.map { ScriptUnspentOutput(output: $0, script: key) }
        }
    }

    func outputs(for amount: UInt64, script: Data) throws -> [UnspentOutput] {
        guard let outputs = outputs[script] else {
            BSDKLogger.error(error: "No outputs for \(script)")
            throw Errors.noOutputs
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        return outputs
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
