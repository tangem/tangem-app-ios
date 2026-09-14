//
//  CryptoFeedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CryptoFeedView: View {
    @ObservedObject var viewModel: CryptoFeedViewModel

    var body: some View {
        LazyVStack(spacing: Constants.sectionSpacing) {
            PromotionNotificationsView(viewModel: viewModel.promoBanner)
                .padding(.horizontal, Constants.horizontalPadding)

            MarketCapView(viewModel: viewModel.marketCap)
            PulseView(viewModel: viewModel.pulse)
        }
    }
}

// MARK: - Constants

private extension CryptoFeedView {
    enum Constants {
        static let sectionSpacing: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
    }
}
