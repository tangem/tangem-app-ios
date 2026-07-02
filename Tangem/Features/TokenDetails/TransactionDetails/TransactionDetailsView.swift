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
    let viewModel: TransactionDetailsViewModel

    private let blocksSpacing: CGFloat = 16

    var body: some View {
        VStack(spacing: .zero) {
            TransactionDetailsHeaderView(data: viewModel.header)

            VStack(spacing: blocksSpacing) {
                ForEach(viewModel.blocks) { blockView($0) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(DesignSystem.Color.bgSecondary)
        .floatingSheetConfiguration { config in
            config.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            config.backgroundInteractionBehavior = .tapToDismiss
            config.verticalSwipeBehavior = .init(target: .sheet, threshold: 100)
        }
    }

    @ViewBuilder
    private func blockView(_ block: TransactionDetailsBlock) -> some View {
        switch block {
        case .tokens(let data):
            TransactionDetailsTokensView(data: data)
        case .statusBanner(let data):
            TransactionDetailsStatusBannerView(data: data)
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
