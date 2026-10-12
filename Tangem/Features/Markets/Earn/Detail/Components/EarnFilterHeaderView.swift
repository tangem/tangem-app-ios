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
    let networksFilter: Filter
    let typesFilter: Filter
    let isLoading: Bool

    @ScaledMetric private var filtersSpacing: CGFloat = 8

    var body: some View {
        HStack(spacing: .zero) {
            if isLoading {
                ChipSkeleton()
            } else {
                filterChip(networksFilter)
            }

            Spacer(minLength: filtersSpacing)

            filterChip(typesFilter)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func filterChip(_ filter: Filter) -> some View {
        RealAssetsCategoryChipView(
            title: filter.title,
            style: filter.isActive ? .selected : .expandable,
            onTap: filter.onTap,
            onClear: filter.onClear
        )
        .disabled(!filter.isEnabled)
    }
}

// MARK: - Filter

extension EarnFilterHeaderView {
    struct Filter {
        let title: String
        let isActive: Bool
        let isEnabled: Bool
        let onTap: () -> Void
        let onClear: () -> Void
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
    func filter(_ title: String, isActive: Bool = false, isEnabled: Bool = true) -> EarnFilterHeaderView.Filter {
        EarnFilterHeaderView.Filter(title: title, isActive: isActive, isEnabled: isEnabled, onTap: {}, onClear: {})
    }

    return VStack(spacing: 16) {
        EarnFilterHeaderView(
            networksFilter: filter("All networks"),
            typesFilter: filter("All types"),
            isLoading: false
        )

        EarnFilterHeaderView(
            networksFilter: filter("Solana", isActive: true),
            typesFilter: filter("Staking", isActive: true),
            isLoading: false
        )

        EarnFilterHeaderView(
            networksFilter: filter("All networks"),
            typesFilter: filter("Yield mode", isActive: true),
            isLoading: true
        )

        EarnFilterHeaderView(
            networksFilter: filter("All networks", isEnabled: false),
            typesFilter: filter("All types"),
            isLoading: false
        )
    }
}
