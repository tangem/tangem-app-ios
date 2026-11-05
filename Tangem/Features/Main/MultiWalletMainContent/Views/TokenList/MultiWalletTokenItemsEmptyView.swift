//
//  MultiWalletTokenItemsEmptyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct MultiWalletTokenItemsEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Assets.emptyTokenList.image
                .foregroundColor(DesignSystem.Color.iconTertiary)

            Text(Localization.mainEmptyTokensListMessage)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Regular.footnote,
                    color: DesignSystem.Color.textSecondary
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 48)
    }
}
