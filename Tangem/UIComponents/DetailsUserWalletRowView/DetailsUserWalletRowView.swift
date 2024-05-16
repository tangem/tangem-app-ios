//
//  DetailsUserWalletRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DetailsUserWalletRowView: View {
    let viewModel: DetailsUserWalletRowViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            content
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        HStack(spacing: 12) {
            icon

            textViews
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var icon: some View {
        switch viewModel.icon {
        case .loading:
            SkeletonView()
                .frame(width: 36, height: 22)
                .cornerRadiusContinuous(3)
        case .loaded(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)

        case .failedToLoad:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
        }
    }

    @ViewBuilder
    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Text(viewModel.cardsCount)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                Text(AppConstants.dotSign)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                LoadableTextView(
                    state: viewModel.balanceState,
                    font: Fonts.Regular.caption1,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 40, height: 12),
                    isSensitiveText: true
                )
            }
            .lineLimit(1)
        }
    }
}

#Preview("DetailsUserWalletRowView") {
    ZStack {
        Colors.Background.tertiary.ignoresSafeArea()

        VStack {
            DetailsUserWalletRowView(
                viewModel: .init(
                    name: "My wallet",
                    cardsCount: 3,
                    isUserWalletLocked: false,
                    totalBalancePublisher: .just(output: .loading),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.walletCard.uiImage)),
                    tapAction: {}
                )
            )

            DetailsUserWalletRowView(
                viewModel: .init(
                    name: "My wallet",
                    cardsCount: 2,
                    isUserWalletLocked: false,
                    totalBalancePublisher: .just(output: .failedToLoad(error: CommonError.noData)),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.walletCard.uiImage)),
                    tapAction: {}
                )
            )

            DetailsUserWalletRowView(
                viewModel: .init(
                    name: "Old wallet",
                    cardsCount: 2,
                    isUserWalletLocked: false,
                    totalBalancePublisher: .just(output: .loaded(.init(balance: 96.75, currencyCode: "USD", hasError: false))),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.darkCard.uiImage)),
                    tapAction: {}
                )
            )

            DetailsUserWalletRowView(
                viewModel: .init(
                    name: "Locked wallet",
                    cardsCount: 2,
                    isUserWalletLocked: true,
                    totalBalancePublisher: .just(output: .failedToLoad(error: CommonError.noData)),
                    cardImagePublisher: .just(output: .embedded(Assets.Onboarding.darkCard.uiImage)),
                    tapAction: {}
                )
            )
        }
        .padding()
    }
}
