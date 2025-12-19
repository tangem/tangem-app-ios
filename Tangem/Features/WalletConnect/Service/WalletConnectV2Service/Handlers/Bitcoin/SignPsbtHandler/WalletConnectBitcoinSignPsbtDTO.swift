//
//  WalletConnectBitcoinSignPsbtDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectBitcoinSignPsbtDTO {
    struct Request: Codable {
        let psbt: String
        let signInputs: [WalletConnectPsbtSignInput]
        let broadcast: Bool?
    }

    struct Response: Codable {
        let psbt: String
        let txid: String?
    }
}
