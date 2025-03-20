//
//  UTXOScriptType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum UTXOScriptType: String, Hashable {
    case p2pkh
    case p2sh
    case p2wpkh
    case p2wsh
    case p2tr

    var inputSize: Int {
        switch self {
        case .p2pkh:
            // signature (71-73 bytes) + pubkey (33 bytes) + script overhead ≈ 148 bytes
            return 148
        case .p2sh:
            // Typical multisig redeem script + signatures + script overhead ≈ 297 bytes
            return 297
        case .p2wpkh:
            // Segregated witness format: signature + pubkey in witness data ≈ 69 bytes
            return 69
        case .p2wsh:
            // Witness program hash (32 bytes) + script version (1 byte) + overhead ≈ 41 bytes
            return 41
        case .p2tr:
            // P2TR: 1 byte version + 32 bytes key + 33 bytes signature
            return 66
        }
    }

    var outputSize: Int {
        switch self {
        case .p2pkh:
            // OP_DUP + OP_HASH160 + push(20) + pubKeyHash(20) + OP_EQUALVERIFY + OP_CHECKSIG = 25 bytes
            return 25
        case .p2sh:
            // OP_HASH160 + push(20) + scriptHash(20) + OP_EQUAL = 23 bytes
            return 23
        case .p2wpkh:
            // Version(1) + push(20) + witness program(20) + script overhead = 22 bytes
            return 22
        case .p2wsh:
            // Version(1) + push(32) + witness program(32) + script overhead = 43 bytes
            return 43
        case .p2tr:
            // P2TR: 1 byte version + 32 bytes key
            return 34
        }
    }
}
