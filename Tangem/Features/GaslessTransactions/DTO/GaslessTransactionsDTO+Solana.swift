//
//  GaslessTransactionsDTO+Solana.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension GaslessTransactionsDTO.Request {
    struct SolanaSubmit: Encodable, Equatable {
        let transaction: String
        let lastValidBlockHeight: UInt64
    }
}

extension GaslessTransactionsDTO.Response {
    struct SolanaFeePayer: Decodable {
        let feePayer: String
    }

    struct SolanaSubmit: Decodable {
        let signature: String
    }
}
