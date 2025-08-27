//
//  KaspaUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class KaspaUnspentOutputManager: CommonUnspentOutputManager {
    static let maxOutputsCount: Int = 1

    override func availableOutputs() -> [ScriptUnspentOutput] {
        let sorted = super.availableOutputs().sorted(by: { $0.amount > $1.amount })
        return Array(sorted.prefix(KaspaUnspentOutputManager.maxOutputsCount))
    }
}
