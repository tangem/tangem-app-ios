//
//  TangemPayOrderCardDataSection.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayOrderCardDataSection: Identifiable {
    let id: ID
    var fields: [TangemPayOrderCardDataField]

    enum ID {
        case cardName
        case recipient
    }
}
