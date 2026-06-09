//
//  TangemPayCloseCardRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayCloseCardRequest: Encodable {
    let cardId: String

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
    }
}
