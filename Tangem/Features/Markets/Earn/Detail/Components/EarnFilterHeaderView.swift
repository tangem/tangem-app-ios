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

    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var filtersSpacing: CGFloat = 8

    var body: some View {
        HStack(spacing: .zero) {
            filterButton(
                title: networkFilterTitle,
                action: onNetworksTap,
                isLoading: isLoading,
                isEnabled: isNetworksFilterEnabled
            )

            Spacer(minLength: filtersSpacing)

            filterButton(
                title: typesFilterTitle,
                action: onTypesTap,
                isLoading: false,
                isEnabled: isTypesFilterEnabled
            )
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, .zero)
    }

    @ViewBuilder
    private func filterButton(
        title: String,
        action: @escaping () -> Void,
        isLoading: Bool,
        isEnabled: Bool
    ) -> some View {
        filterButtonRedesign(
            title: title,
            action: action,
            isLoading: isLoading,
            isEnabled: isEnabled
        )
    }

    @ViewBuilder
    private func filterButtonRedesign(
        title: String,
        action: @escaping () -> Void,
        isLoading: Bool,
        isEnabled: Bool
    ) -> some View {
        if isLoading {
            ButtonSkeleton()
        } else {
            TangemUI.Button(
                label: title,
                accessibilityLabel: title,
                action: action
            )
            .iconEnd(DesignSystem.Icons.ChevronDown.regular20)
            .size(.x9)
            .styleType(.secondary)
            .isLoading(isLoading)
            .disabled(!isEnabled)
        }
    }
}

private struct ButtonSkeleton: View {
    var body: some View {
        Shimmer()
            .variant(.custom(width: 142, height: 36))
    }
}
