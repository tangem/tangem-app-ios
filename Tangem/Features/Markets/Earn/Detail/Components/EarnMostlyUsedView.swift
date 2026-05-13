//
//  EarnMostlyUsedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

struct EarnMostlyUsedView: View {
    let viewModels: LoadingResult<[EarnTokenItemViewModel], Error>
    var fourthItemAppearIndex: Int = Constants.defaultFourthItemAppearIndex
    var onFourthItemAppeared: (() -> Void)?

    var body: some View {
        contentView
            .scrollIndicators(.hidden)
            .frame(height: Layout.height)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModels {
        case .loading, .failure:
            skeletonView
        case .success(let viewModels):
            loadedView(viewModels: viewModels)
        }
    }

    private var skeletonView: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.cardSpacing) {
                ForEach(0 ..< Constants.skeletonCount, id: \.self) { _ in
                    EarnTokenTileSkeletonView()
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .scrollDisabled(true)
    }

    private func loadedView(viewModels: [EarnTokenItemViewModel]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.cardSpacing) {
                ForEach(Array(viewModels.enumerated()), id: \.element.id) { index, viewModel in
                    EarnTokenTileView(viewModel: viewModel)
                        .onAppear {
                            if index == fourthItemAppearIndex {
                                onFourthItemAppeared?()
                            }
                        }
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
    }
}

extension EarnMostlyUsedView {
    enum Constants {
        static let defaultFourthItemAppearIndex = 3
        static let skeletonCount = 5
    }
}

private extension EarnMostlyUsedView {
    enum Layout {
        static let height: CGFloat = FeatureProvider.isAvailable(.redesign) ? 130.0 : 106.0
        static let cardSpacing: CGFloat = 8.0
        static let horizontalPadding: CGFloat = 16.0
    }
}
