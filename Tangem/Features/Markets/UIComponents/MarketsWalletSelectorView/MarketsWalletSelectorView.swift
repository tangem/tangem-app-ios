//
//  MarketsWalletSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

struct MarketsWalletSelectorView: View {
    @ObservedObject var viewModel: MarketsWalletSelectorViewModel

    var body: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            }

            Spacer()

            Assets.chevron.image
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundColor(Colors.Icon.informative)
        }
        .frame(maxWidth: .infinity)
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var icon: some View {
        image
            .frame(width: 36, height: 36)
            .skeletonable(
                isShown: viewModel.icon.isLoading,
                size: CGSize(width: 36, height: 22),
                paddings: EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            )
    }

    @ViewBuilder
    private var image: some View {
        switch viewModel.icon {
        case .loading:
            Color.clear

        case .success(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failure:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    ZStack {
        Colors.Background.tertiary.ignoresSafeArea()

        VStack {
            MarketsWalletSelectorView(
                viewModel: MarketsWalletSelectorViewModel(
                    infoProvider: UserWalletModelMock()
                )
            )

            MarketsWalletSelectorView(
                viewModel: MarketsWalletSelectorViewModel(
                    infoProvider: UserWalletModelMock()
                )
            )

            MarketsWalletSelectorView(
                viewModel: MarketsWalletSelectorViewModel(
                    infoProvider: UserWalletModelMock()
                )
            )
        }
        .padding()
    }
}
