//
//  EarnGetTokenSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnGetTokenSheetView: View {
    let viewModel: EarnGetTokenSheetViewModel

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.items) { row($0) }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.bottom, Constants.bottomPadding)
    }

    private func row(_ item: TokenDetailsActionRowItem) -> some View {
        Row(title: item.title, subtitle: item.subtitle)
            .titleLineLimit(Constants.labelLineLimit)
            .subtitleLineLimit(Constants.labelLineLimit)
            .start {
                Avatar(.icon(item.icon, appearance: .info), size: .size40)
                    .accessibilityHidden(true)
            }
            .end { chevron }
            .onTap(action: item.action)
            .disabled(!item.isAvailable)
            .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    private var chevron: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .flipsForRightToLeftLayoutDirection(true)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension EarnGetTokenSheetView {
    enum Constants {
        static let horizontalPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 16
        static let labelLineLimit = 2
    }
}
