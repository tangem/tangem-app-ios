//
//  EarnFilterHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct EarnFilterHeaderView: View {
    let isNetworksFilterEnabled: Bool
    let isTypesFilterEnabled: Bool
    let isLoading: Bool
    let networkFilterTitle: String
    let typesFilterTitle: String
    let onNetworksTap: () -> Void
    let onTypesTap: () -> Void

    @ScaledMetric private var filtersSpacing: CGFloat = 8

    var body: some View {
        HStack(spacing: .zero) {
            if isLoading {
                ChipSkeleton()
            } else {
                filterChip(
                    title: networkFilterTitle,
                    isEnabled: isNetworksFilterEnabled,
                    action: onNetworksTap
                )
            }

            Spacer(minLength: filtersSpacing)

            filterChip(
                title: typesFilterTitle,
                isEnabled: isTypesFilterEnabled,
                action: onTypesTap
            )
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func filterChip(
        title: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        RealAssetsCategoryChipView(title: title, style: .expandable, onTap: action)
            .disabled(!isEnabled)
    }
}

// MARK: - Layout

private extension EarnFilterHeaderView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16.0
    }
}

private struct ChipSkeleton: View {
    @ScaledMetric private var width: CGFloat = 142
    @ScaledMetric private var height: CGFloat = 36

    var body: some View {
        Shimmer()
            .variant(.custom(width: width, height: height, cornerRadius: height / 2))
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        EarnFilterHeaderView(
            isNetworksFilterEnabled: true,
            isTypesFilterEnabled: true,
            isLoading: false,
            networkFilterTitle: "All networks",
            typesFilterTitle: "All types",
            onNetworksTap: {},
            onTypesTap: {}
        )

        EarnFilterHeaderView(
            isNetworksFilterEnabled: true,
            isTypesFilterEnabled: true,
            isLoading: true,
            networkFilterTitle: "All networks",
            typesFilterTitle: "Staking",
            onNetworksTap: {},
            onTypesTap: {}
        )

        EarnFilterHeaderView(
            isNetworksFilterEnabled: false,
            isTypesFilterEnabled: true,
            isLoading: false,
            networkFilterTitle: "All networks",
            typesFilterTitle: "Yield",
            onNetworksTap: {},
            onTypesTap: {}
        )
    }
}
