//
//  WCSolanaSignAllTransactionsDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCSolanaSignAllTransactionsDTO {
    struct Body: Codable {
        let transactions: [String]
    }

    struct Response: Codable {
        let transactions: [String]
    }
}
