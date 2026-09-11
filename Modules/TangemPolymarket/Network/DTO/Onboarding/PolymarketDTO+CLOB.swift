//
//  PolymarketDTO+CLOB.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct CredentialsResponse: Decodable {
        let apiKey: String
        let secret: String
        let passphrase: String
    }

    struct BalanceAllowanceResponse: Decodable {
        let balance: String
        let allowance: String?
    }
}
