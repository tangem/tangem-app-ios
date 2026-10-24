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
        if let displayModel = viewModel.displayModel {
            TangemPayTransactionDetailsContentView(state: displayModel, action: handle)
                .floatingSheetConfiguration { configuration in
                    configuration.maxHeightFraction = Constants.maxHeightFraction
                    configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
                    configuration.backgroundInteractionBehavior = .tapToDismiss
                }
        } else {
            // Logically it's dead code since TangemPayTransactionDeeplinkResponder will drop cases where displayModel is not being built.
            // But to safely remove it we need to move TangemPayTransactionDetailsDisplayModel into init params of ViewModel.
            legacyBody
        }
    }

    private func handle(_ action: TangemPayTransactionDetailsContentView.Action) {
        switch action {
        case .close: viewModel.userDidTapClose()
        case .mainButton: viewModel.userDidTapMainButton()
        case .retryCardLoad: viewModel.retryCardLoad()
        case .retryCashbackLoad: viewModel.retryCashbackLoad()
        }
    }

    private var legacyBody: some View {
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

private extension TangemPayTransactionDetailsView {
    enum Constants {
        static let maxHeightFraction: CGFloat = 0.9
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
        warning(text: TangemPayTransactionDeclineReasonMapper.declinedText(for: reason))
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
