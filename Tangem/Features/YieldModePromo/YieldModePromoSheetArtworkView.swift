//
//  YieldModePromoSheetArtworkView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct YieldModePromoSheetArtworkView: View {
    let height: CGFloat

    var body: some View {
        Color.clear
            .frame(height: height)
            .overlay {
                // [REDACTED_TODO_COMMENT]
                Assets.YieldModule.yieldModulePromoV2Header.image
            }
            .accessibilityHidden(true)
    }
}
