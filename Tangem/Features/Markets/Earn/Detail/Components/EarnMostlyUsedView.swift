//
//  EarnMostlyUsedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct EarnMostlyUsedView: View {
    let viewModels: [EarnTokenItemViewModel]
    var fourthItemAppearIndex: Int = Constants.defaultFourthItemAppearIndex
    var onFourthItemAppeared: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: Layout.cardSpacing) {
                ForEach(Array(viewModels.enumerated()), id: \.element.id) { index, viewModel in
                    EarnMostlyUsedTileView(viewModel: viewModel)
                        .onAppear {
                            if index == fourthItemAppearIndex {
                                onFourthItemAppeared?()
                            }
                        }
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .scrollIndicators(.hidden)
        .frame(height: Layout.height)
    }
}

extension EarnMostlyUsedView {
    enum Constants {
        static let defaultFourthItemAppearIndex = 3
    }
}

private extension EarnMostlyUsedView {
    enum Layout {
        static let height: CGFloat = 106.0
        static let cardSpacing: CGFloat = 8.0
        static let horizontalPadding: CGFloat = 16.0
    }
}
