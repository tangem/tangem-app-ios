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
    // [REDACTED_INFO]: Remove legacy defaults and use redesign colors (Graphic/Neutral/quaternary, Text/Neutral/tertiary) and spacing (.x5)
    private var iconColor: Color = Colors.Icon.inactive
    private var textColor: Color = Colors.Text.tertiary
    private var spacing: CGFloat = 16

    var body: some View {
        VStack(spacing: spacing) {
            Assets.emptyTokenList.image
                .foregroundColor(iconColor)

            Text(Localization.mainEmptyTokensListMessage)
                .multilineTextAlignment(.center)
                .style(
                    Fonts.Regular.footnote,
                    color: textColor
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 48)
    }
}

// MARK: - Setupable

extension MultiWalletTokenItemsEmptyView: Setupable {
    func iconColor(_ color: Color) -> Self {
        map { $0.iconColor = color }
    }

    func textColor(_ color: Color) -> Self {
        map { $0.textColor = color }
    }

    func spacing(_ spacing: CGFloat) -> Self {
        map { $0.spacing = spacing }
    }
}
