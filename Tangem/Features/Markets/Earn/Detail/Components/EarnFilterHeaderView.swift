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
    let isNetworksFilterEnabled: Bool
    let isTypesFilterEnabled: Bool
    let isLoading: Bool
    let networkFilterTitle: String
    let typesFilterTitle: String
    let onNetworksTap: () -> Void
    let onTypesTap: () -> Void

    var body: some View {
        HStack(spacing: Layout.filterSpacing) {
            filterButton(
                title: networkFilterTitle,
                action: onNetworksTap,
                isLoading: isLoading,
                isEnabled: isNetworksFilterEnabled
            )

            Spacer()

            filterButton(
                title: typesFilterTitle,
                action: onTypesTap,
                isLoading: false,
                isEnabled: isTypesFilterEnabled
            )
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
    }

    private func filterButton(
        title: String,
        action: @escaping () -> Void,
        isLoading: Bool,
        isEnabled: Bool
    ) -> some View {
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
            .opacity(isEnabled ? Layout.enabledOpacity : Layout.disabledOpacity)
            .skeletonable(isShown: isLoading, radius: Layout.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
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
        static let enabledOpacity = 1.0
        static let disabledOpacity = 0.7
    }
}
