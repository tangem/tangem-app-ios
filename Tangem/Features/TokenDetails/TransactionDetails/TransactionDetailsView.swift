//
//  TransactionDetailsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TransactionDetailsView: View {
    @ObservedObject var viewModel: TransactionDetailsViewModel

    private let blocksSpacing: CGFloat = 16

    var body: some View {
        VStack(spacing: .zero) {
            TransactionDetailsHeaderView(data: viewModel.header)

            VStack(spacing: blocksSpacing) {
                ForEach(viewModel.blocks) { block in
                    blockView(block)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.blocks.map(\.id))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(DesignSystem.Color.bgSecondary)
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            // [REDACTED_TODO_COMMENT]
        }
    }

    @ViewBuilder
    private func blockView(_ block: TransactionDetailsBlock) -> some View {
        switch block {
        case .tokens(let data):
            TransactionDetailsTokensView(data: data)
        case .yieldTokens(let data):
            TransactionDetailsYieldTokensView(data: data)
        case .statusBanner(let data):
            TransactionDetailsStatusBannerView(data: data)
        case .principalAmount(let data):
            TransactionDetailsPrincipalAmountView(data: data)
        case .counterparty(let data):
            TransactionDetailsAddressView(data: data)
        case .info(let data):
            TransactionDetailsInfoSectionView(data: data)
        case .action(let data):
            TransactionDetailsActionButtonView(data: data)
        }
    }
}

// MARK: - Previews

#Preview("Received") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.received())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Sent") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.sent())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Swap in progress") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.swapInProgress())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Swap finished") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.swapFinished())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Swap failed") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.swapFailed())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Onramp in progress") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.onrampInProgress())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Onramp finished") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.onrampFinished())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Onramp failed") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.onrampFailed())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Staking") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.staking())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Approve") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.approve())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Fee") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.fee())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Yield") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.yieldEnabled())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Other") {
    TransactionDetailsView(viewModel: TransactionDetailsPreviewFactory.other())
        .background(DesignSystem.Color.bgPrimary)
}
