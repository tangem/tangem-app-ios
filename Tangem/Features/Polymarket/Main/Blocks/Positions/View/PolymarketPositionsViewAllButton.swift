//
//  PolymarketPositionsViewAllButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct PolymarketPositionsViewAllButton: View {
    let action: () -> Void

    var body: some View {
        TangemUI.Button(
            label: Localization.predictionPositionsViewAllActive,
            accessibilityLabel: nil,
            action: action
        )
        .size(.x9)
        .styleType(.secondary(.default))
    }
}
