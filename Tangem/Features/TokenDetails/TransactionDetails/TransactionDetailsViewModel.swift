//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

final class TransactionDetailsViewModel: FloatingSheetContentViewModel {
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
        case .sendReceive(let data): data.blocks
        case .swap(let viewModel): viewModel.blocks
        case .onramp(let viewModel): viewModel.blocks
        case .blocks(let blocks): blocks
        }
    }

    enum Content {
        case sendReceive(TransactionDetailsSendReceiveViewData)
        case swap(SwapTransactionDetailsViewData)
        case onramp(OnrampTransactionDetailsViewData)
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
