//
//  UTXOLockingScript.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct UTXOLockingScript: Hashable {
    /// `Ripemd160(Hash256(PublicKey))` or `Ripemd160(Hash256(RedeemScript))` for `p2ms(Multisig)`
    public let keyHash: Data

    /// `Locking Script Data` Will be use in output
    public let data: Data

    /// The type which impact on `redeemScript` and `lockingScript`
    public let type: UTXOScriptType
}
