//
//  PolymarketRegionRestrictionViewModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

public final class PolymarketRegionRestrictionViewModel: ObservableObject, FloatingSheetContentViewModel {
    let title: String
    let message: String

    private let onClose: () -> Void

    public init(title: String, message: String, onClose: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.onClose = onClose
    }

    func onCloseTap() {
        onClose()
    }
}

// MARK: - Notices

public extension PolymarketRegionRestrictionViewModel {
    static func regionRestriction(onClose: @escaping () -> Void) -> PolymarketRegionRestrictionViewModel {
        PolymarketRegionRestrictionViewModel(
            title: Localization.predictionRegionRestrictionsTitle,
            message: Localization.predictionRegionRestrictionsSubtitle,
            onClose: onClose
        )
    }

    // [REDACTED_TODO_COMMENT]
    static func marketClosed(onClose: @escaping () -> Void) -> PolymarketRegionRestrictionViewModel {
        PolymarketRegionRestrictionViewModel(
            title: "Market closed",
            message: "This market has stopped taking orders. Nothing was placed and nothing left your account.",
            onClose: onClose
        )
    }

    // [REDACTED_TODO_COMMENT]
    static func quoteUnavailable(onClose: @escaping () -> Void) -> PolymarketRegionRestrictionViewModel {
        PolymarketRegionRestrictionViewModel(
            title: Localization.commonSomethingWentWrong,
            message: "The current price is out of reach right now. Nothing was placed and nothing left your account.",
            onClose: onClose
        )
    }
}
