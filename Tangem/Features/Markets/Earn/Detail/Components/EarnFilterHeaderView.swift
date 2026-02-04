//
//  EarnFilterHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct EarnFilterHeaderView: View {
    let isFilterInteractionEnabled: Bool
    let networkFilterTitle: String
    let typesFilterTitle: String
    let onNetworksTap: () -> Void
    let onTypesTap: () -> Void

    var body: some View {
        HStack(spacing: Layout.filterSpacing) {
            filterButton(
                title: networkFilterTitle,
                action: onNetworksTap,
                isEnabled: isFilterInteractionEnabled
            )

            Spacer()

            filterButton(
                title: typesFilterTitle,
                action: onTypesTap,
                isEnabled: isFilterInteractionEnabled
            )
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
    }

    private func filterButton(title: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: Layout.buttonContentSpacing) {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Assets.chevronDownMini.image
            }
            .padding(.horizontal, Layout.buttonHorizontalPadding)
            .padding(.vertical, Layout.buttonVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                    .fill(Colors.Button.secondary)
            )
        }
        .style(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? Layout.enabledOpacity : Layout.disabledOpacity)
    }
}

private extension EarnFilterHeaderView {
    enum Layout {
        static let filterSpacing: CGFloat = 8.0
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 8.0
        static let buttonContentSpacing: CGFloat = 6.0
        static let buttonHorizontalPadding: CGFloat = 10.0
        static let buttonVerticalPadding: CGFloat = 6.0
        static let buttonCornerRadius: CGFloat = 8.0
    }
}
