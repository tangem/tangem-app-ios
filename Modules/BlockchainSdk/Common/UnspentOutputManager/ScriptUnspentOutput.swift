//
//  ScriptUnspentOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ScriptUnspentOutput: Hashable {
    let output: UnspentOutput
    let script: UTXOLockingScript

    var blockId: Int { output.blockId }
    var hash: Data { output.hash }
    var index: Int { output.index }
    var amount: UInt64 { output.amount }
    var txId: String { output.txId }
}
