//
//  PolymarketDTO+SessionKey.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct SessionKey: Decodable {
        let address: String
        let deviceId: String?
        let deviceName: String?
        let enabled: Bool?
        let status: String
        let scopes: [String]?
        let validUntil: Int?
        let renewAfter: Int?
        let authorizedAt: Int?
        let createdAt: Int?
    }
}
