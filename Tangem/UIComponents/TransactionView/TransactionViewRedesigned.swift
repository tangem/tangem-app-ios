//
//  TransactionViewRedesigned.swift
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

struct TransactionViewRedesigned: View {
    let viewModel: TransactionViewModel

    @ScaledMetric private var iconContainerSide: CGFloat = 40
    @ScaledMetric private var glyphSize: CGFloat = 20
    @ScaledMetric private var iconBorderWidth: CGFloat = 1
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

    private var rowLayout: some View {
        TangemTwoLineRowLayout(
            icon: { iconView },
            primaryLeading: { nameView },
            primaryTrailing: { amountView },
            secondaryLeading: { subtitleView },
            secondaryTrailing: { secondaryTrailingView }
        )
        .compressionPolicy(.trailingPreserved)
    }

    private func warningView(_ warning: TransactionViewModel.Warning) -> some View {
        HStack(spacing: .unit(.x3)) {
            DesignSystem.Icons.Error.filled16.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: warningIconSize, height: warningIconSize)
                .frame(width: iconContainerSide)
                .foregroundStyle(DesignSystem.Color.iconStatusWarning)

            Text(warningTitle(for: warning))
                .style(Font.Tangem.Caption12.medium, color: DesignSystem.Color.textStatusWarning)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.top, .unit(.x2))
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
        HStack(spacing: .unit(.x2)) {
            Text(display.title)
                .style(Font.Tangem.Body16.medium, color: nameColor)
                .lineLimit(1)
                .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionItem(key: transactionKey))

            if viewModel.inProgress {
                ProgressDots(style: .small)
            }
        }
    }

    private var amountView: some View {
        SensitiveText(viewModel.amount.value)
            .style(Font.Tangem.Body16.medium, color: amountColor)
            .strikethrough(isFailed, color: amountColor)
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
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                .lineLimit(1)
                .truncationMode(viewModel.transactionDescriptionTruncationMode)
                .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionSubtitle(key: transactionKey))

        case .express(let model):
            TransactionExpressSubtitleView(model: model)

        case .none:
            EmptyView()
        }
    }

    private var secondaryTrailingView: some View {
        HStack(spacing: 4) {
            if FeatureProvider.isAvailable(.tangemPayCashback), let cashback = viewModel.cashback {
                TransactionCashbackBadge(cashback: cashback)
            }

            if let text = viewModel.secondaryTrailingText {
                Text(text)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
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

private extension TransactionViewRedesigned {
    var isFailed: Bool { viewModel.icon.status == .failed }

    var nameColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Text.Status.warning
        case .inProgress: .Tangem.Text.Status.accent
        case .confirmed: .Tangem.Text.Neutral.primary
        }
    }

    var amountColor: Color {
        if let tangemPayAmountColor {
            return tangemPayAmountColor
        }

        switch viewModel.icon.status {
        case .failed, .undefined, .inProgress: return .Tangem.Text.Neutral.tertiary
        case .confirmed: return .Tangem.Text.Neutral.primary
        }
    }

    var tangemPayAmountColor: Color? {
        guard case .tangemPay(let payType) = viewModel.transactionType else { return nil }

        switch payType {
        case .spend(_, _, let isDeclined, _) where isDeclined:
            return .Tangem.Text.Status.warning
        case .spend(_, _, _, let isNegativeAmount) where isNegativeAmount:
            return .Tangem.Text.Status.accent
        case .transfer where !viewModel.isOutgoing:
            return .Tangem.Text.Status.accent
        case .spend, .transfer, .fee:
            return nil
        }
    }

    var iconBackgroundColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Markers.backgroundTintedRed
        case .inProgress: .Tangem.Markers.backgroundTintedBlue
        case .confirmed: .Tangem.Markers.backgroundTintedGray
        }
    }

    var iconGlyphColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Markers.iconRed
        case .inProgress: .Tangem.Markers.iconBlue
        case .confirmed: .Tangem.Graphic.Neutral.secondary
        }
    }
}

// MARK: - Previews

#Preview("States") {
    VStack(spacing: 16) {
        TransactionViewRedesigned(
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
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
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
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
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
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
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
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
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
                isFromYieldContract: false
            )
        )

        TransactionViewRedesigned(
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
                warning: .verifying
            )
        )

        TransactionViewRedesigned(
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
                cashback: TransactionViewModel.Cashback(formattedAmount: "+$5.00", style: .estimated)
            )
        )

        TransactionViewRedesigned(
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
                cashback: TransactionViewModel.Cashback(formattedAmount: "+$5.00", style: .confirmed)
            )
        )
    }
    .padding()
    .background(Colors.Background.secondary)
}
