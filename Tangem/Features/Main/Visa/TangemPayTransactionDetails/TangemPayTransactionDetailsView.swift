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
        if let additionalInfo = viewModel.additionalInfo {
            HStack(spacing: 8) {
                additionalInfo.icon
                    .renderingMode(.template)
                    .foregroundStyle(additionalInfo.iconColor)

                Text(additionalInfo.text)
                    .style(Fonts.Regular.footnote, color: additionalInfo.textColor)
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(additionalInfo.backgroundColor)
            )
        }
    }
}

extension TangemPayTransactionDetailsView {
    struct AdditionalInfo {
        let text: String
        let textColor: Color
        let icon: Image
        let iconColor: Color
        let backgroundColor: Color
    }
}

extension TangemPayTransactionDetailsView.AdditionalInfo {
    static func declined(reason: String?) -> Self {
        let text = if let reason {
            Localization.tangemPayHistoryItemSpendMcDeclinedReason(reason)
        } else {
            Localization.tangemPayTransactionDeclinedNotificationText
        }
        return warning(text: text)
    }

    static let fee: Self = warning(text: Localization.tangemPayTransactionFeeNotificationText)

    static let reversed: Self = .init(
        text: Localization.tangemPayTransactionReversedNotificationText,
        textColor: Colors.Text.tertiary,
        icon: Assets.infoCircle20.image,
        iconColor: Colors.Icon.secondary,
        backgroundColor: Colors.Button.disabled
    )

    private static func warning(text: String) -> Self {
        .init(
            text: text,
            textColor: Colors.Text.warning,
            icon: Assets.infoCircle20.image,
            iconColor: Colors.Icon.warning,
            backgroundColor: Colors.Icon.warning.opacity(0.1)
        )
    }
}
