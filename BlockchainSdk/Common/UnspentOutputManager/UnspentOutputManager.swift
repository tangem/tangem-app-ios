//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: String) throws
    func update(outputs: [UnspentOutput], for script: UTXOLockingScript)

    func preImage(amount: UInt64, fee: UInt64, destination: String) throws -> PreImageTransaction
    func preImage(amount: UInt64, feeRate: UInt64, destination: String) throws -> PreImageTransaction

    func allOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: any Address) {
        switch address {
        case let address as LockingScriptAddress:
            update(outputs: outputs, for: address.lockingScript)
        case let address:
            do {
                BSDKLogger.warning("Update outputs with plain address. Better to use LockingScriptAddress in your address service")
                try update(outputs: outputs, for: address.value)
            } catch {
                BSDKLogger.error("Update outputs error", error: error)
            }
        }
    }
}

struct PreImageTransaction {
    let inputs: [ScriptUnspentOutput]
    let outputs: [OutputType]
    let fee: UInt64
}

extension PreImageTransaction {
    enum OutputType {
        case destination(UTXOLockingScript, value: UInt64)
        case change(UTXOLockingScript, value: UInt64)

        var script: UTXOLockingScript {
            switch self {
            case .destination(let script, _): script
            case .change(let script, _): script
            }
        }

        var value: UInt64 {
            switch self {
            case .destination(_, let value): value
            case .change(_, let value): value
            }
        }
    }
}
