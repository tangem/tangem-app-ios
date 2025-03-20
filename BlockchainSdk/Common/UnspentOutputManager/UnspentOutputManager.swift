//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: String)
    func update(outputs: [UnspentOutput], for script: UTXOLockingScript)

    func preImage(amount: UInt64, fee: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction
    func preImage(amount: UInt64, feeRate: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction

    func allOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: any Address) {
        guard let address = address as? LockingScriptAddress else {
            BSDKLogger.error(error: "The address for UnspentOutputManager is not LockingScriptAddress")
            return
        }

        update(outputs: outputs, for: address.lockingScript)
    }
}
