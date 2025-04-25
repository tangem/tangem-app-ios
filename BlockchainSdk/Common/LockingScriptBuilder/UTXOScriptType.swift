//
//  UTXOScriptType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum UTXOScriptType: Hashable {
    /// Currently used only for `Kaspa`
    case p2pk
    case p2pkh
    case p2sh(redeemScript: Data?)

    case p2wpkh
    case p2wsh(redeemScript: Data?)

    case p2tr
}
