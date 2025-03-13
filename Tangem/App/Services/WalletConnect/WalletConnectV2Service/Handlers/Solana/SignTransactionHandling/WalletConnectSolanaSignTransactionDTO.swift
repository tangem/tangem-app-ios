//
//  WalletConnectSolanaSignTransactionDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectSolanaSignTransactionDTO {
    struct Body: Codable {
        /// `Signature` is signed transaction data encoded as base-58 string
        let signature: String
    }

    struct Response: Codable {
        /// `Transaction` is raw base-64 encoded transaction string with dummy signature
        let transaction: String
    }
}
