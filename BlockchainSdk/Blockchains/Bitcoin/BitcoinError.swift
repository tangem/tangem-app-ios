//
//  BitcoinError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

public enum BitcoinError: LocalizedError {
    case invalidBase64
    case invalidPsbt(String)
    case unsupported(String)
    case inputIndexOutOfRange(Int)
    case missingUtxo(Int)
    case wrongSignaturesCount

    public var errorDescription: String? {
        switch self {
        case .invalidPsbt(let message):
            return message
        case .inputIndexOutOfRange(let index):
            return "PSBT input index out of range: \(index)"
        case .missingUtxo(let vout):
            return "Missing UTXO for vout \(vout)"
        case .wrongSignaturesCount:
            return "Wrong signatures count"
        case .unsupported(let reason):
            return "Unsupported PSBT scriptPubKey: \(reason)"
        case .invalidBase64:
            return "Invalid base64 PSBT"
        }
    }
}
