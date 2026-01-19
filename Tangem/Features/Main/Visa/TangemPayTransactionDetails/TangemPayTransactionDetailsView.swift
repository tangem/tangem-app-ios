//
//  TangemPayTransactionDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayTransactionDetailsView: View {
    @ObservedObject var viewModel: TangemPayTransactionDetailsViewModel

    var body: some View {
        VStack(spacing: 24) {
            BottomSheetHeaderView(title: viewModel.title, trailing: {
                NavigationBarButton.close(action: viewModel.userDidTapClose)
            })
            .verticalPadding(8)

            mainContainer
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.primary
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }

    private var mainContainer: some View {
        VStack(spacing: 32) {
            TransactionViewIconView(data: viewModel.iconData, size: .large)

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    VStack(spacing: 2) {
                        Text(viewModel.name)
                            .style(Fonts.Bold.body, color: Colors.Text.primary1)

                        Text(viewModel.category)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }

                    VStack(spacing: 4) {
                        TransactionViewAmountView(data: viewModel.amount, size: .large)

                        if let localAmount = viewModel.localAmount {
                            Text(localAmount)
                                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                        }
                    }
                }

                if let state = viewModel.state {
                    TangemPayTransactionDetailsStateView(state: state)
                }
            }

            bottomContainer
        }
    }

    private var bottomContainer: some View {
        VStack(spacing: 8) {
            bottomInfoView
                .padding(.vertical, 8)

            MainButton(
                title: viewModel.mainButtonAction.title,
                style: .secondary,
                action: viewModel.userDidTapMainButton
            )
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var bottomInfoView: some View {
        if let bottomInfo = viewModel.bottomInfo {
            HStack(spacing: 8) {
                Assets.infoCircle20.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.secondary)

                Text(bottomInfo)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Colors.Button.disabled)
            )
        }
    }
}
