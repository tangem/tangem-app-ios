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
    case p2sh

    case p2wpkh
    case p2wsh

    case p2tr

    var isWitness: Bool {
        switch self {
        case .p2wsh, .p2wpkh, .p2tr: true
        case .p2pk, .p2pkh, .p2sh: false
        }
    }
}
