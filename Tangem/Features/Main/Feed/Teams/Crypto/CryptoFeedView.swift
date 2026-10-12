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
        VStack(spacing: Constants.sectionSpacing) {
            PromotionNotificationsView(
                viewModel: viewModel.promoBanner,
                paginationSpacing: 0,
                paginationMinHeight: Constants.paginationMinHeight
            )
            .padding(.horizontal, Constants.horizontalPadding)
            .clipped()
            MarketCapView(viewModel: viewModel.marketCap)
            PulseView(viewModel: viewModel.pulse)
        }
    }
}

// MARK: - Constants

private extension CryptoFeedView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let paginationMinHeight: CGFloat = 32
        static let sectionSpacing: CGFloat = 36
    }
}
