//
//  TangemPayPinRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPaySetPinRequest: Encodable {
    let pin: String
    let sessionId: String
    let iv: String

    enum CodingKeys: String, CodingKey {
        case pin
        case sessionId = "session_id"
        case iv
    }
}
