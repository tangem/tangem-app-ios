//
//  TangemPayFreezeUnfreezeRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayFreezeUnfreezeRequest: Encodable {
    let cardId: String

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
    }
}
