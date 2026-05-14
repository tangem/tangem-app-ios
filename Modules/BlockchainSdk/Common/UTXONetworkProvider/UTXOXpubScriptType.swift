//
//  UTXOXpubScriptType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Script type of an xpub descriptor used to fetch addresses for a UTXO wallet.
public enum UTXOXpubScriptType: Hashable {
    case p2pkh(xpub: String)
    case p2wpkh(xpub: String)

    func wrapped() -> String {
        switch self {
        case .p2pkh(let xpub): "pkh(\(xpub))"
        case .p2wpkh(let xpub): "wpkh(\(xpub))"
        }
    }
}
