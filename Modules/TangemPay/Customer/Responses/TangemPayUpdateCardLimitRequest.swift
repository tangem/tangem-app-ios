//
//  TangemPayUpdateCardDisplayNameRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayUpdateCardLimitRequest: Encodable {
    let cardLimit: CardLimitRequest?

    struct CardLimitRequest: Encodable {
        let amount: Int
    }
}
