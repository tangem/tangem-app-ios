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
    func outputs(for amount: UInt64, script: Data) throws -> [UnspentOutput]

    func allOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: any Address) {
        guard let address = address as? LockingScriptAddress else {
            assertionFailure("The address is not a LockingScriptAddress")
            return
        }

        update(outputs: outputs, for: address.scriptPubKey)
    }
}
