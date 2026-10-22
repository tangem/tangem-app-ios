//
//  TokenSelectorLoadingView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct TokenSelectorLoadingView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()

            Text(Localization.wcCommonLoading)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        }
        .padding(.top, 12)
    }
}
