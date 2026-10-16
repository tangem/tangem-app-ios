//
//  TransactionChipRedesigned.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

/// Compact chip used for technical transactions (Staking, Approve, Yield Mode) per the Phase 1
/// redesign spec. Hosts the same title + amount + subtitle composition as the full row, just
/// packed into a capsule and centered horizontally between full-row neighbours.
///
/// Per Figma node `7013:46986`, examples include:
/// - `Approved 2,350.00 USDT to: <icon> Open Sea`
/// - `Yield mode enabled` (no amount, no subtitle)
struct TransactionChipRedesigned: View {
    let viewModel: TransactionViewModel
    let style: TransactionDisplayModel.ChipStatusStyle

    private var display: TransactionDisplayModel { viewModel.display }

    private var transactionKey: String { viewModel.transactionType.accessibilityIdentifierKey }

    var body: some View {
        HStack(spacing: 4) {
            leadingIcon

            if let failedApproveAmount {
                SensitiveText(builder: failedApproveTitle, sensitive: failedApproveAmount)
                    .style(DesignSystem.Font.captionMediumToken, color: titleColor)
                    .lineLimit(1)
                    .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionItem(key: transactionKey))
            } else {
                titleView

                if let amountText {
                    SensitiveText(builder: amountWithCurrency, sensitive: amountText)
                        .style(DesignSystem.Font.captionMediumToken, color: amountColor)
                        .lineLimit(1)
                }

                subtitleView
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(background)
        .clipShape(Capsule(style: .continuous))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var amountText: String? {
        switch style {
        case .error:
            return nil
        case .progress, .plain, .success:
            return viewModel.amount.displayValue?.nilIfEmpty
        }
    }

    /// A failed approve keeps its allowance, folded into a single `Approving <amount> failed` sentence
    /// instead of the `<title> <amount>` composition every other state uses.
    private var failedApproveAmount: String? {
        guard viewModel.transactionType == .approve else {
            return nil
        }

        switch style {
        case .error:
            return viewModel.amount.displayValue?.nilIfEmpty
        case .progress, .plain, .success:
            return nil
        }
    }

    private func failedApproveTitle(_ amount: String) -> String {
        Localization.commonActionFailed("\(Localization.commonApproving) \(amountWithCurrency(amount))")
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch style {
        case .progress:
            Loader()
                .loaderSize(.size16)
                .loaderColor(DesignSystem.Color.iconStatusInfo)
        case .error:
            iconImage(DesignSystem.Icons.Cross.regular16.image)
        case .success:
            iconImage(DesignSystem.Icons.Success.regular16.image)
        case .plain where isOperationGlyphVisible:
            iconImage(viewModel.icon.redesignedIcon)
        case .plain:
            EmptyView()
        }
    }

    private var isOperationGlyphVisible: Bool {
        viewModel.transactionType != .approve && !isProviderChip
    }

    private var isProviderChip: Bool {
        if case .provider = display.subtitle {
            return true
        }

        return false
    }

    private func iconImage(_ image: Image) -> some View {
        image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: 16))
            .foregroundStyle(titleColor)
    }

    private var titleView: some View {
        Text(attributedTitle)
            .style(DesignSystem.Font.captionMediumToken, color: titleColor)
            .lineLimit(1)
            .accessibilityIdentifier(TxHistoryAccessibilityIdentifiers.transactionItem(key: transactionKey))
    }

    private var attributedTitle: AttributedString {
        switch display.title {
        case .plain(let text):
            return AttributedString(text)
        case .emphasizedSuffix(let prefix, let emphasized):
            var emphasizedPart = AttributedString(emphasized)
            emphasizedPart.foregroundColor = DesignSystem.Color.textPrimary

            return AttributedString(prefix) + emphasizedPart
        }
    }

    private func amountWithCurrency(_ value: String) -> String {
        viewModel.amount.currencyCode.isEmpty
            ? value
            : value + " " + viewModel.amount.currencyCode
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch display.subtitle {
        case .owner(let direction, let owner) where isCounterpartyVisible:
            TransactionSubtitleView(direction: direction, owner: owner, isAddressEmphasized: true)

        case .provider(let direction, let provider) where isCounterpartyVisible:
            TransactionProviderSubtitleView(direction: direction, provider: provider)

        case .owner, .text, .express, .provider, .none:
            EmptyView()
        }
    }

    private var isCounterpartyVisible: Bool {
        switch style {
        case .error:
            return false
        case .progress, .plain, .success:
            return true
        }
    }

    private var titleColor: Color {
        switch style {
        case .error: DesignSystem.Color.textStatusError
        case .progress: DesignSystem.Color.textStatusInfo
        case .plain: DesignSystem.Color.textSecondary
        case .success: DesignSystem.Color.textStatusSuccess
        }
    }

    private var amountColor: Color {
        switch style {
        case .plain, .success: DesignSystem.Color.textPrimary
        case .progress, .error: titleColor
        }
    }

    private var background: Color {
        switch style {
        case .error: DesignSystem.Color.bgStatusErrorSubtle
        case .progress: DesignSystem.Color.bgStatusInfoSubtle
        case .plain: DesignSystem.Color.bgTransparentSecondary
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        }
    }
}

// MARK: - Previews

#if DEBUG

private enum ChipPreviewFixture {
    static let types: [TransactionViewModel.TransactionType] = [
        .stake, .unstake, .approve,
        .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin, .yieldTopup, .yieldSend,
        .incentiveClaimCoin,
    ]
    static let statuses: [TransactionViewModel.Status] = [.inProgress, .confirmed, .failed]

    static let combinations: [TransactionViewModel] = types.flatMap { type in
        statuses.map { status in
            TransactionViewModel(
                hash: UUID().uuidString,
                index: 0,
                interactionAddress: .contract("0x0000...0000"),
                timeFormatted: "10:45",
                amount: "2,350.00 USDT",
                value: "2,350.00",
                currencyCode: "USDT",
                isOutgoing: type != .yieldSend,
                transactionType: type,
                status: status,
                isFromYieldContract: type == .yieldSend
            )
        }
    }
}

#Preview("Chip variants") {
    VStack(spacing: 8) {
        ForEach(Array(ChipPreviewFixture.combinations.enumerated()), id: \.offset) { _, model in
            if case .chip(let style) = model.display.style {
                TransactionChipRedesigned(viewModel: model, style: style)
            }
        }
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}

#endif // DEBUG
