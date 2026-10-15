//
//  TangemPayBankTransferRail.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

enum TangemPayBankTransferRail {
    case ach
    case wire

    var title: String {
        switch self {
        case .ach: "ACH"
        case .wire: "FedWire"
        }
    }

    var eta: String {
        switch self {
        case .ach: Localization.tangempayOrderTypeDeliveryEtaRange(1, 3)
        case .wire: Localization.tangempayWithdrawBankEtaSameBusinessDay
        }
    }

    var fee: String {
        switch self {
        case .ach: "$1.5"
        case .wire: "$15"
        }
    }

    var texts: [String] {
        [title, eta, fee]
    }

    func isDisplayed(by elements: XCUIElementQuery) -> Bool {
        let label = elements.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        return texts.allSatisfy(label.contains)
    }
}
