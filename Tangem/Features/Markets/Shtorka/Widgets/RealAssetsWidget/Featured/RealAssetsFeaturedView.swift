//
//  RealAssetsFeaturedView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct RealAssetsFeaturedView: View {
    @ObservedObject var viewModel: RealAssetsFeaturedViewModel

    var body: some View {
        switch viewModel.state {
        case .loading:
            section {
                carousel {
                    ForEach(0 ..< Layout.skeletonTilesCount, id: \.self) { _ in
                        RealAssetsFeaturedTileSkeletonView()
                    }
                }
                .scrollDisabled(true)
            }

        case .loaded(let items) where !items.isEmpty:
            section {
                carousel {
                    ForEach(items) { item in
                        RealAssetsFeaturedTileView(item: item)
                    }
                }
            }

        case .loaded:
            EmptyView()
        }
    }

    private func section(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Layout.titleSpacing) {
            Text(Localization.marketsRealAssetsFeaturedAssets)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            content()
        }
        .padding(.bottom, Layout.bottomPadding)
    }

    private func carousel(@ViewBuilder content: () -> some View) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.tileSpacing) {
                content()
            }
            .padding(.horizontal, Layout.hostHorizontalPadding)
        }
        .padding(.horizontal, -Layout.hostHorizontalPadding)
    }
}

// MARK: - Layout

private extension RealAssetsFeaturedView {
    enum Layout {
        static let titleSpacing: CGFloat = 16
        static let bottomPadding: CGFloat = 12
        static let tileSpacing: CGFloat = 8
        static let hostHorizontalPadding: CGFloat = 16
        static let skeletonTilesCount = 3
    }
}
