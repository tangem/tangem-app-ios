//
//  PolymarketOrderFlowStyle.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemUI

enum PolymarketOrderFlowStyle {
    case summaryStep
    case singleSheet(SingleSheet)

    init(isSingleSheetEnabled: Bool, side: PolymarketOrderSide, singleSheet: @autoclosure () -> SingleSheet) {
        self = isSingleSheetEnabled && side == .buy ? .singleSheet(singleSheet()) : .summaryStep
    }

    var singleSheet: SingleSheet? {
        switch self {
        case .summaryStep: nil
        case .singleSheet(let singleSheet): singleSheet
        }
    }

    var isSingleSheet: Bool {
        singleSheet != nil
    }
}

// MARK: - SingleSheet

extension PolymarketOrderFlowStyle {
    struct SingleSheet {
        let placementService: PolymarketOrderPlacementService
        let signingButtonType: SigningActionButtonViewType
    }
}
