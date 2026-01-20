//
//  TangemPayGetPinRequest.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayGetPinRequest: Encodable {
    let cardId: String
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case sessionId = "session_id"
    }
}
