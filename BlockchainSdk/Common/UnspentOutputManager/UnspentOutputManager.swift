//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: ScriptUnspentOutput.Script)
    func preImage(amount: UInt64, fee: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction
    func preImage(amount: UInt64, feeRate: UInt64) throws -> UTXOPreImageTransactionBuilder.PreImageTransaction

    func allOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: LockingScriptAddress) {
        update(outputs: outputs, for: address.scriptPubKey)
    }
}
