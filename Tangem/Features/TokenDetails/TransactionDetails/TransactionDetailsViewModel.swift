//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

@MainActor
final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    let header: TransactionDetailsHeaderViewData
    let content: Content

    init(
        header: TransactionDetailsHeaderViewData,
        content: Content
    ) {
        self.header = header
        self.content = content
    }

    var blocks: [TransactionDetailsBlock] {
        switch content {
        case .send(let viewModel): viewModel.blocks
        case .receive(let viewModel): viewModel.blocks
        case .swap(let viewModel): viewModel.blocks
        case .onramp(let viewModel): viewModel.blocks
        case .blocks(let blocks): blocks
        }
    }

    enum Content {
        case send(SendTransactionDetailsViewModel)
        case receive(ReceiveTransactionDetailsViewModel)
        case swap(SwapTransactionDetailsViewModel)
        case onramp(OnrampTransactionDetailsViewModel)
        case blocks([TransactionDetailsBlock])
    }
}

enum TransactionDetailsBlock: Identifiable {
    case tokens(TransactionDetailsTokensViewData)
    case statusBanner(TransactionDetailsStatusBannerViewData)
    case counterparty(TransactionDetailsAddressViewData)
    case info(TransactionDetailsInfoSectionViewData)
    case action(TransactionDetailsActionButtonViewData)

    var id: String {
        switch self {
        case .tokens: "tokens"
        case .statusBanner: "statusBanner"
        case .counterparty: "counterparty"
        case .info: "info"
        case .action: "action"
        }
    }
}
