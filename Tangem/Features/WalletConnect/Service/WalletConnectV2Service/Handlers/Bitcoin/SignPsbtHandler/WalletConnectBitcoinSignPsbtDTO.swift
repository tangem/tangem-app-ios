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
        let signInputs: [SignInput]
        let broadcast: Bool?
    }

    struct SignInput: Codable {
        let address: String
        let index: Int
        let sighashTypes: [Int]?
    }

    struct Response: Codable {
        let psbt: String
        let txid: String?
    }
}
