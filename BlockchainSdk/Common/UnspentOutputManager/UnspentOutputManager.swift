//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: Data)
    func selectOutputs(amount: UInt64, fee: UTXOSelector.Fee) throws -> [ScriptUnspentOutput]

    func allOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: LockingScriptAddress) {
        update(outputs: outputs, for: address.scriptPubKey)
    }
}
