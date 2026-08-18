//
//  TangemPayOrderCardInfoRow.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct TangemPayOrderCardInfoRow: Identifiable {
    let id: ID
    let title: String
    var value: String
    var subvalue: String?
    var badge: Badge?
    var isValueStruckThrough = false
    var isDimmed = false

    enum ID {
        case issueFee
        case issueTime
        case deliverTo
        case deliveryFee
        case deliveryTime
    }

    struct Badge {
        let text: String
        let appearance: BadgeAppearance
    }
}
