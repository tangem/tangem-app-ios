//
//  TransactionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TransactionView: View {
    let viewModel: TransactionViewModel

    @ScaledMetric private var iconContainerSide: CGFloat = 40
    @ScaledMetric private var glyphSize: CGFloat = 20
    @ScaledMetric private var warningIconSize: CGFloat = 16

    private var display: TransactionDisplayModel { viewModel.display }

    private var transactionKey: String { viewModel.transactionType.accessibilityIdentifierKey }

    private var statusAccessibilityIdentifier: String? {
        switch viewModel.icon.status {
        case .confirmed: TxHistoryAccessibilityIdentifiers.transactionConfirmedStatus(key: transactionKey)
        case .inProgress: TxHistoryAccessibilityIdentifiers.transactionInProgressStatus(key: transactionKey)
        case .failed, .undefined: nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            rowLayout

            if let warning = viewModel.warning {
                warningView(warning)
            }
        }
    }

    @ViewBuilder
    private var rowLayout: some View {
        if let value = viewModel.amount.displayValue {
            TangemTwoLineRowLayout(
                icon: { iconView },
                primaryLeading: { nameView },
                primaryTrailing: { amountView(value) },
                secondaryLeading: { subtitleView },
                secondaryTrailing: { secondaryTrailingView }
            )
            .compressionPolicy(.trailingPreserved)
        } else {
            // Without an amount the top trailing slot would be blank, leaving the ticker hanging off the
            // bottom line, so the whole trailing column moves to the centre instead.
            TangemTwoLineRowLayout(
                icon: { iconView },
                primaryLeading: { nameView },
                secondaryLeading: { subtitleView },
                centeredTrailing: { secondaryTrailingView }
            )
            .compressionPolicy(.trailingPreserved)
        }
    }

    private func warningView(_ warning: TransactionViewModel.Warning) -> some View {
        HStack(spacing: 12) {
            DesignSystem.Icons.Error.filled16.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: warningIconSize, height: warningIconSize)
                .frame(width: iconContainerSide)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)

            Text(warningTitle(for: warning))
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textStatusWarning)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private func warningTitle(for warning: TransactionViewModel.Warning) -> String {
        switch warning {
        case .verifying:
            Localization.expressExchangeNotificationVerificationTitle
        case .paused:
            Localization.expressExchangeStatusPaused
        }
    }

    private var iconView: some View {
        ZStack {
            Circle().fill(iconBackgroundColor)

            iconContent
        }
        .frame(width: iconContainerSide, height: iconContainerSide)
        .accessibilityIdentifier(statusAccessibilityIdentifier)
    }

    @ViewBuilder
    private var iconContent: some View {
        if case .tangemPay(.spend(_, let iconURL?, _, _)) = viewModel.transactionType {
            IconView(
                url: iconURL,
                size: CGSize(bothDimensions: iconContainerSide),
                cornerRadius: iconContainerSide / 2
            ) {
                glyphImage
            }
        } else {
            glyphImage
        }
    }

    private var glyphImage: some View {
        viewModel.icon.icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: glyphSize, height: glyphSize)
            .foregroundStyle(iconGlyphColor)
    }

    private var nameView: some View {
        HStack(spacing: 8) {
            Text(display.title.fullText)
                .style(DesignSystem.Font.bodyMediumToken, color: nameColor)
                .lineLimit(1)
                .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionItem(key: transactionKey))

            if rowStatus == .progress {
                ProgressDots(style: .small)
            }
        }
    }

    private func amountView(_ value: String) -> some View {
        SensitiveText(value)
            .strikethroughWhenVisible(isFailed, color: amountColor)
            .style(DesignSystem.Font.bodyMediumToken, color: amountColor)
            .lineLimit(1)
            .layoutPriority(1)
            .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionAmount(key: transactionKey))
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch display.subtitle {
        case .owner(let direction, let owner):
            TransactionSubtitleView(
                direction: direction,
                owner: owner,
                accessibilityIdentifier: TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: transactionKey)
            )

        case .text(let description):
            Text(description)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .truncationMode(viewModel.transactionDescriptionTruncationMode)
                .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: transactionKey))

        case .express(let model):
            TransactionExpressSubtitleView(model: model)

        case .provider(let direction, let provider):
            TransactionProviderSubtitleView(
                direction: direction,
                provider: provider,
                accessibilityIdentifier: TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: transactionKey)
            )

        case .sentAsset(let sent):
            TransactionSentAssetSubtitleView(
                sent: sent,
                accessibilityIdentifier: TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: transactionKey)
            )

        case .none:
            EmptyView()
        }
    }

    private var secondaryTrailingView: some View {
        HStack(spacing: 4) {
            if let cashback = viewModel.cashback {
                TransactionCashbackBadge(cashback: cashback)
                    .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionCashback(key: transactionKey))
            }

            if let text = viewModel.secondaryTrailingText {
                Text(text)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionCurrency(key: transactionKey))
            }
        }
    }
}

// MARK: - Cashback badge

private struct TransactionCashbackBadge: View {
    let cashback: TransactionViewModel.Cashback

    @ObservedObject private var visibilityState: SensitiveTextVisibilityState = .shared

    var body: some View {
        Badge(label: label, accessibilityLabel: nil)
            .size(.x4)
            .variant(.tinted)
            .appearance(appearance)
    }

    private var label: String {
        visibilityState.isHidden ? visibilityState.maskedBalanceString : cashback.formattedAmount
    }

    private var appearance: BadgeAppearance {
        switch cashback.style {
        case .estimated: .neutral
        case .confirmed: .info
        }
    }
}

// MARK: - Status-driven styling

private extension TransactionView {
    enum RowStatus {
        case progress
        case pending
        case finished
        case failed
    }

    var rowStatus: RowStatus {
        if viewModel.isPendingSignature {
            return .pending
        }

        switch viewModel.icon.status {
        case .failed, .undefined: return .failed
        case .inProgress: return .progress
        case .confirmed: return .finished
        }
    }

    var isFailed: Bool { viewModel.icon.status == .failed }

    var nameColor: Color {
        switch rowStatus {
        case .failed: DesignSystem.Color.textAccentRed
        case .progress: DesignSystem.Color.textAccentBlue
        case .pending: DesignSystem.Color.textStatusWarning
        case .finished: DesignSystem.Color.textPrimary
        }
    }

    var amountColor: Color {
        if let tangemPayAmountColor {
            return tangemPayAmountColor
        }

        switch rowStatus {
        case .failed, .progress, .pending: return DesignSystem.Color.textSecondary
        case .finished: return DesignSystem.Color.textPrimary
        }
    }

    var tangemPayAmountColor: Color? {
        guard case .tangemPay(let payType) = viewModel.transactionType else { return nil }

        switch payType {
        case .spend(_, _, let isDeclined, _) where isDeclined:
            return DesignSystem.Color.textAccentRed
        case .spend(_, _, _, let isNegativeAmount) where isNegativeAmount:
            return DesignSystem.Color.textAccentBlue
        case .transfer where !viewModel.isOutgoing,
             .cashback:
            return DesignSystem.Color.textAccentBlue
        case .spend, .transfer, .fee:
            return nil
        }
    }

    var iconBackgroundColor: Color {
        switch rowStatus {
        case .failed: DesignSystem.Color.bgStatusErrorSubtle
        case .progress: DesignSystem.Color.bgStatusInfoSubtle
        case .pending: DesignSystem.Color.bgStatusWarningSubtle
        case .finished: DesignSystem.Color.bgTransparentPrimary
        }
    }

    var iconGlyphColor: Color {
        switch rowStatus {
        case .failed: DesignSystem.Color.iconAccentRed
        case .progress: DesignSystem.Color.iconAccentBlue
        case .pending: DesignSystem.Color.iconStatusWarning
        case .finished: DesignSystem.Color.iconSecondary
        }
    }
}

// MARK: - Previews

#Preview("States") {
    VStack(spacing: 16) {
        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "−350.31 USDT",
                value: "−350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .confirmed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.31 USDT",
                value: "+350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .inProgress,
                isFromYieldContract: false,
                isTangemPayCounterparty: false
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "350.31 USDT",
                value: "350.31",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .transfer,
                status: .failed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.00 USDT",
                value: "+350.00",
                currencyCode: "USDT",
                isOutgoing: false,
                transactionType: .swap,
                status: .confirmed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "+350.00 USDT",
                value: "+350.00",
                currencyCode: "USDT",
                isOutgoing: false,
                transactionType: .swap,
                status: .inProgress,
                isFromYieldContract: false,
                isTangemPayCounterparty: false
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "−390.00 USDT",
                value: "−390.00",
                currencyCode: "USDT",
                isOutgoing: true,
                transactionType: .swap,
                status: .inProgress,
                isFromYieldContract: false,
                isTangemPayCounterparty: false,
                warning: .verifying
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .custom(message: "Restaurants"),
                timeFormatted: "10:45",
                amount: "−$12.34",
                value: "−$12.34",
                currencyCode: "",
                isOutgoing: true,
                transactionType: .tangemPay(.spend(name: "Tangem Coffee", icon: nil, isDeclined: false, isNegativeAmount: false)),
                status: .confirmed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false,
                cashback: TransactionViewModel.Cashback(formattedAmount: "+$5.00", style: .estimated)
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .custom(message: "Restaurants"),
                timeFormatted: "10:45",
                amount: "−$12.34",
                value: "−$12.34",
                currencyCode: "",
                isOutgoing: true,
                transactionType: .tangemPay(.spend(name: "Tangem Coffee", icon: nil, isDeclined: false, isNegativeAmount: false)),
                status: .confirmed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false,
                cashback: TransactionViewModel.Cashback(formattedAmount: "+$5.00", style: .confirmed)
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .custom(message: "Restaurants"),
                timeFormatted: "10:45",
                amount: "+$12.34",
                value: "+$12.34",
                currencyCode: "",
                isOutgoing: false,
                transactionType: .tangemPay(.spend(name: "Tangem Coffee", icon: nil, isDeclined: false, isNegativeAmount: true)),
                status: .confirmed,
                isFromYieldContract: false,
                isTangemPayCounterparty: false,
                cashback: TransactionViewModel.Cashback(formattedAmount: "−$5.00", style: .confirmed)
            )
        )

        TransactionView(
            viewModel: TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .user("33BdfS...ga2B"),
                timeFormatted: "10:45",
                amount: "−0.3212 ETH",
                value: "−0.3212",
                currencyCode: "ETH",
                isOutgoing: true,
                transactionType: .transfer,
                status: .inProgress,
                isFromYieldContract: false,
                isTangemPayCounterparty: false,
                isPendingSignature: true
            )
        )
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}
