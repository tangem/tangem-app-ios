//
// KaspaUtils.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaUtils {
    enum KaspaHashType: String {
        case TransactionSigningHashECDSA
        case TransactionID
        case TransactionHash

        var data: Data {
            rawValue.data(using: .utf8)!
        }
    }
}
