//
//  RatingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct RatingView: View {
    @ObservedObject var viewModel: RatingViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                skeletonView
            case .unrated, .submitting:
                CardView(
                    displayRating: viewModel.displayRating,
                    onRatingSelected: viewModel.onRatingSelected
                )
            case .rated(let rating), .submitted(let rating):
                CardView(displayRating: rating)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        .task {
            await viewModel.load()
        }
    }
}

private extension RatingView {
    // MARK: - Subviews

    var skeletonView: some View {
        Color.clear
            .frame(height: 92)
            .frame(maxWidth: .infinity)
            .background(Colors.Background.action)
            .cornerRadius(14)
            .skeletonable(isShown: true, radius: 14)
    }
}

// MARK: - Previews

#Preview {
    struct RatingViewPreviewStub: RatingProvider {
        func checkExisting(for transactionId: String) async throws -> ExistingRating? { nil }
        func submit(request: RatingRequest) async throws {}
    }

    return RatingView(
        viewModel: RatingViewModel(
            model: RatingModel(
                ratingProvider: RatingViewPreviewStub(),
                transaction: .init(transactionId: "tx_123", providerName: "1inch", txUrl: nil),
                userWalletIdHash: "hash"
            )
        )
    )
    .padding()
}
