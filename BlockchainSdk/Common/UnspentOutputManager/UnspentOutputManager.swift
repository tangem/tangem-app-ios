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
}
