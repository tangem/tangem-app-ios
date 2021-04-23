//
//  ScriptType.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum BitcoinCoreScriptType: Int {
    case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh, nullData

    var size: Int {
        switch self {
        case .p2pk: return 35
        case .p2pkh: return 25
        case .p2sh: return 23
        case .p2wsh: return 34
        case .p2wpkh: return 22
        case .p2wpkhSh: return 23
        default: return 0
        }
    }

    var witness: Bool {
        self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh
    }

    var nativeSegwit: Bool {
        self == .p2wpkh || self == .p2wsh
    }

}
