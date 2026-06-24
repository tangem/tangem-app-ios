//
//  TransactionDetailsView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TransactionDetailsView: View {
    @ObservedObject var viewModel: TransactionDetailsViewModel

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

#if DEBUG
extension TransactionDetailsViewModel {
    static func previewReceive() -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            header: .init(
                title: "Received",
                date: "Jan 20 2026, 9:24 PM",
                operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: false),
                menuActions: .transactionDetailsPreview,
                onClose: {}
            ),
            content: .receive(.preview())
        )
    }

    static func previewSent() -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(
            header: .init(
                title: "Sent",
                date: "Jan 20 2026, 9:24 PM",
                operationIcon: .init(type: .transfer, status: .confirmed, isOutgoing: true),
                menuActions: .transactionDetailsPreview,
                onClose: {}
            ),
            content: .send(.preview())
        )
    }
}

#Preview("Received") {
    TransactionDetailsView(viewModel: .previewReceive())
        .background(DesignSystem.Color.bgPrimary)
}

#Preview("Sent") {
    TransactionDetailsView(viewModel: .previewSent())
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
