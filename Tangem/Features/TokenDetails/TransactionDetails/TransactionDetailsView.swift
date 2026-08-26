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

    private let blocksSpacing: CGFloat = 12

    var body: some View {
        ZStack {
            if let feedback = viewModel.presentedFeedback {
                RatingFeedbackBottomSheetView(viewModel: feedback)
                    .transition(.content)
            } else {
                detailsContent
                    .transition(.content)
            }
        }
        .animation(.contentFrameUpdate, value: viewModel.presentedFeedback == nil)
    }

    private var detailsContent: some View {
        VStack(spacing: .zero) {
            if let header = viewModel.header {
                TransactionDetailsHeaderView(data: header, onAction: viewModel.handleViewAction)
            }

            TransactionDetailsBlocksView(
                blocks: viewModel.blocks,
                spacing: blocksSpacing,
                onAction: viewModel.handleViewAction
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .background(DesignSystem.Color.bgSecondary)
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
            config.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }
}

// MARK: - Blocks

private struct TransactionDetailsBlocksView: View {
    let blocks: [TransactionDetailsBlock]
    let spacing: CGFloat
    let onAction: (TransactionDetailsViewModel.ViewAction) -> Void

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(blocks) { block in
                TransactionDetailsBlockView(block: block, onAction: onAction)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: blocks.map(\.id))
    }
}

private struct TransactionDetailsBlockView: View {
    let block: TransactionDetailsBlock
    let onAction: (TransactionDetailsViewModel.ViewAction) -> Void

    var body: some View {
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
            TransactionDetailsAddressView(data: data, onAction: onAction)
        case .info(let data):
            TransactionDetailsInfoSectionView(data: data, onAction: onAction)
        case .action(let data):
            TransactionDetailsActionButtonView(data: data, onTap: { onAction(data.action) })
        case .rating(let viewModel):
            RatingView(viewModel: viewModel)
        }
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
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
