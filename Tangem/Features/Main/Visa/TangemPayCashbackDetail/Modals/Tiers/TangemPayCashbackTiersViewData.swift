//
//  TangemPayCashbackTiersViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayCashbackTiersViewData: Identifiable {
    let title: String
    let rows: [Row]

    var id: String { title }
}

extension TangemPayCashbackTiersViewData {
    struct Row: Identifiable {
        let id: String
        let text: String
    }
}

// MARK: - Previews

#if DEBUG
extension TangemPayCashbackTiersViewData {
    static let preview = TangemPayCashbackTiersViewData(
        title: "Cashback 1%",
        rows: [
            Row(id: "basic", text: "1% for all purchases with your Basic cards, min purchase $30"),
            Row(id: "eu-excluded", text: "No cashback for in-person purchases at EU merchants"),
            Row(id: "paid-in", text: "Paid in USDC"),
            Row(id: "cap", text: "$150 max per month"),
        ]
    )

    static let previewMultipleTiers = TangemPayCashbackTiersViewData(
        title: "Cashback up to 2%",
        rows: [
            Row(id: "basic", text: "1% for all purchases with your Basic cards, min purchase $30"),
            Row(id: "plus", text: "2% for all purchases with your Plus cards, min purchase $30"),
            Row(id: "eu-excluded", text: "No cashback for in-person purchases at EU merchants"),
            Row(id: "paid-in", text: "Paid in USDC"),
            Row(id: "cap", text: "$150 max per month"),
        ]
    )
}
#endif
