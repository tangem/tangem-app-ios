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

    @ScaledMetric private var horizontalPadding: CGFloat = .unit(.x4)
    @ScaledMetric private var verticalPadding: CGFloat = .unit(.x2)
    @ScaledMetric private var filtersSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var buttonContentSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var buttonHorizontalPadding: CGFloat = .unit(.x3)
    @ScaledMetric private var buttonVerticalPadding: CGFloat = .unit(.x2)
    @ScaledMetric private var buttonCornerRadius: CGFloat = .unit(.x2)

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
            TangemButton(
                content: .combined(
                    text: AttributedString(title),
                    icon: Assets.chevronDown24,
                    iconPosition: .right
                ),
                action: action
            )
            .setStyleType(.primaryInverse)
            .setSize(.x9)
            .setButtonState(isLoading: isLoading, isDisabled: !isEnabled)
        }
    }
}

private struct ButtonSkeleton: View {
    @ScaledMetric private var height: CGFloat = 36
    @ScaledMetric private var width: CGFloat = 142

    var body: some View {
        SkeletonView()
            .frame(width: width, height: height)
            .clipShape(.capsule)
    }
}
