//
//  TransferInputRailItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemPay

struct TransferInputRailItem: Identifiable, Equatable {
    let rail: TangemPayBankAccountRail
    let icon: ImageType
    let title: String
    let etaText: String
    let feeText: String
    let feeAmount: Decimal

    var id: TangemPayBankAccountRail { rail }
}

// MARK: - Previews

#if DEBUG
extension TransferInputRailItem {
    static let previewList = [
        TransferInputRailItem(
            rail: .ach,
            icon: Assets.Visa.railAch,
            title: "ACH",
            etaText: "1-3 business days",
            feeText: "$1",
            feeAmount: 1
        ),
        TransferInputRailItem(
            rail: .wire,
            icon: Assets.Visa.railFedwire,
            title: "FedWire",
            etaText: "Same business day",
            feeText: "$11",
            feeAmount: 11
        ),
    ]
}
#endif
