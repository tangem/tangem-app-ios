//
//  RealAssetsFeedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct RealAssetsFeedView: View {
    @ObservedObject var viewModel: RealAssetsFeedViewModel

    var body: some View {
        VStack(spacing: Constants.sectionSpacing) {
            PromotionNotificationsView(viewModel: viewModel.promoBanner)

            content
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var content: some View {
        if let shelfViewModel = viewModel.shelfViewModel {
            RealAssetsContentView(viewModel: shelfViewModel)
        } else {
            skeleton
        }
    }

    private var skeleton: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< Constants.skeletonRowsCount, id: \.self) { _ in
                TokenRowMarket(.shimmer)
            }
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: .zero, radius: Constants.listCornerRadius)
    }
}

// MARK: - Constants

private extension RealAssetsFeedView {
    enum Constants {
        static let sectionSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let listCornerRadius: CGFloat = 24
        static let skeletonRowsCount = 5
    }
}
