//
//  EarnFeedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnFeedView: View {
    @ObservedObject var viewModel: EarnFeedViewModel

    var body: some View {
        content
            .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var content: some View {
        if let earnViewModel = viewModel.earnViewModel {
            EarnContentView(viewModel: earnViewModel)
        } else {
            skeleton
        }
    }

    private var skeleton: some View {
        VStack(spacing: .zero) {
            ForEach(0 ..< Constants.skeletonRowsCount, id: \.self) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: .zero, radius: Constants.listCornerRadius)
        .padding(.horizontal, Constants.horizontalPadding)
    }
}

// MARK: - Constants

private extension EarnFeedView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let listCornerRadius: CGFloat = 24
        static let skeletonRowsCount = 5
    }
}
