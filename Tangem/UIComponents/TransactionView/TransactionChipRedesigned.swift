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

    var body: some View {
        HStack(spacing: .unit(.x1)) {
            titleView

            if viewModel.amount.value.isNotEmpty {
                Text(amountWithCurrency)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
            }

            subtitleView

            if viewModel.inProgress {
                ProgressDots(style: .small)
            }
        }
        .padding(.horizontal, .unit(.x3))
        .padding(.vertical, .unit(.x1))
        .background(background)
        .clipShape(Capsule(style: .continuous))
        .overlay(border)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var titleView: some View {
        Text(display.title)
            .style(Font.Tangem.Caption12.semibold, color: titleColor)
            .lineLimit(1)
    }

    private var amountWithCurrency: String {
        viewModel.amount.currencyCode.isEmpty
            ? viewModel.amount.value
            : viewModel.amount.value + " " + viewModel.amount.currencyCode
    }

    @ViewBuilder
    private var subtitleView: some View {
        switch display.subtitle {
        case .owner(let direction, let owner):
            TransactionSubtitleView(direction: direction, owner: owner)

        case .text, .none:
            EmptyView()
        }
    }

    private var titleColor: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Text.Status.warning
        case .inProgress: .Tangem.Text.Status.accent
        case .confirmed: .Tangem.Text.Neutral.secondary
        }
    }

    private var background: Color {
        switch viewModel.icon.status {
        case .failed, .undefined: .Tangem.Markers.backgroundTintedRed
        case .inProgress: .Tangem.Markers.backgroundTintedBlue
        case .confirmed: .Tangem.Markers.backgroundTintedGray
        }
    }

    @ViewBuilder
    private var border: some View {
        switch viewModel.icon.status {
        case .failed, .undefined:
            Capsule(style: .continuous).strokeBorder(Color.Tangem.Markers.borderTintedRed, lineWidth: 1)
        case .inProgress:
            Capsule(style: .continuous).strokeBorder(Color.Tangem.Markers.borderTintedBlue, lineWidth: 1)
        case .confirmed:
            Capsule(style: .continuous).strokeBorder(Color.Tangem.Markers.borderGray, lineWidth: 1)
        }
    }
}

// MARK: - Previews

#if DEBUG

private enum ChipPreviewFixture {
    static let types: [TransactionViewModel.TransactionType] = [.stake, .unstake, .approve, .yieldEnter, .yieldWithdraw]
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
                isOutgoing: true,
                transactionType: type,
                status: status,
                isFromYieldContract: false
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
