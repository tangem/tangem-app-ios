//
//  ScriptUnspentOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct ScriptUnspentOutput {
    let output: UnspentOutput
    /// Can be named as `LockedScript, ScriptPubKey, ScriptPubKey.hex`
    let script: UTXOLockingScript

    var blockId: Int { output.blockId }
    var hash: Data { output.hash }
    var index: Int { output.index }
    var amount: UInt64 { output.amount }
    var txId: String { output.txId }
}

struct SignedUnspentOutput {
    let output: UnspentOutput
    let signedLockingScript: Data

    var blockId: Int { output.blockId }
    var hash: Data { output.hash }
    var index: Int { output.index }
    var amount: UInt64 { output.amount }
    var txId: String { output.txId }
}
