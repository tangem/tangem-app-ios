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
    let title = Localization.predictionRegionRestrictionsTitle

    let message = Localization.predictionRegionRestrictionsSubtitle

    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func onCloseTap() {
        onClose()
    }
}
