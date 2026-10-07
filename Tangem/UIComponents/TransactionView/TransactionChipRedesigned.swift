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

    private var display: TransactionDisplayModel { viewModel.display }

    private var transactionKey: String { viewModel.transactionType.accessibilityIdentifierKey }

    var body: some View {
        HStack(spacing: .unit(.x1)) {
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
        .padding(.horizontal, .unit(.x3))
        .padding(.vertical, .unit(.x1))
        .background(background)
        .clipShape(Capsule(style: .continuous))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var amountText: String? {
        switch viewModel.icon.status {
        case .failed, .undefined:
            return nil
        case .inProgress, .confirmed:
            return viewModel.amount.displayValue?.nilIfEmpty
        }
    }

    /// A failed approve keeps its allowance, folded into a single `Approving <amount> failed` sentence
    /// instead of the `<title> <amount>` composition every other state uses.
    private var failedApproveAmount: String? {
        guard viewModel.transactionType == .approve else {
            return nil
        }

        switch viewModel.icon.status {
        case .failed, .undefined:
            return viewModel.amount.displayValue?.nilIfEmpty
        case .inProgress, .confirmed:
            return nil
        }
    }

    private func failedApproveTitle(_ amount: String) -> String {
        Localization.commonActionFailed("\(Localization.commonApproving) \(amountWithCurrency(amount))")
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch viewModel.icon.status {
        case .inProgress:
            Loader()
                .loaderSize(.size16)
                .loaderColor(DesignSystem.Color.iconStatusInfo)
        case .failed, .undefined:
            iconImage(DesignSystem.Icons.Cross.regular16.image)
        case .confirmed where isOperationGlyphVisible:
            iconImage(viewModel.icon.redesignedIcon)
        case .confirmed:
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

        case .provider(let direction) where isCounterpartyVisible:
            TransactionProviderSubtitleView(direction: direction)

        case .owner, .text, .express, .provider, .none:
            EmptyView()
        }
    }

    private var isCounterpartyVisible: Bool {
        switch viewModel.icon.status {
        case .failed, .undefined:
            return false
        case .inProgress, .confirmed:
            return true
        }
    }

    private var titleColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: DesignSystem.Color.textStatusError
        case .inProgress: DesignSystem.Color.textStatusInfo
        case .confirmed: DesignSystem.Color.textSecondary
        }
    }

    private var amountColor: Color {
        switch viewModel.icon.status {
        case .confirmed: DesignSystem.Color.textPrimary
        case .inProgress, .failed, .undefined: titleColor
        }
    }

    private var background: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: DesignSystem.Color.bgStatusErrorSubtle
        case .inProgress: DesignSystem.Color.bgStatusInfoSubtle
        case .confirmed: DesignSystem.Color.bgTransparentSecondary
        }
    }
}

// MARK: - Previews

#if DEBUG

private enum ChipPreviewFixture {
    static let types: [TransactionViewModel.TransactionType] = [
        .stake, .unstake, .approve,
        .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin, .yieldTopup, .yieldSend,
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
    VStack(spacing: .unit(.x2)) {
        ForEach(Array(ChipPreviewFixture.combinations.enumerated()), id: \.offset) { _, model in
            TransactionChipRedesigned(viewModel: model)
        }
    }
    .padding()
    .background(Color.Tangem.Surface.level1)
}

#endif // DEBUG
