//
//  WCWalletRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WCWalletRowView: View {
    @ObservedObject var viewModel: SettingsUserWalletRowViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            content
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!viewModel.isUserWalletLocked)
    }

    private var content: some View {
        HStack(spacing: 12) {
            icon

            textViews
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .contentShape(Rectangle())
        .drawingGroup()
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

        case .loaded(let image):
            image.image
                .resizable()
                .aspectRatio(contentMode: .fit)

        case .failedToLoad:
            Assets.Onboarding.darkCard.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private var textViews: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.name)
                .lineLimit(1)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            HStack(spacing: 4) {
                Text("\(viewModel.tokensCount) tokens")
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                if viewModel.balanceState != .empty {
                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    LoadableTokenBalanceView(
                        state: viewModel.balanceState,
                        style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                        loader: .init(size: CGSize(width: 40, height: 12))
                    )
                }
            }
            .lineLimit(1)
        }
    }
}
