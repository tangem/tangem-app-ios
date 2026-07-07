//
//  TransactionDetailsOperationViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum TransactionDetailsOperationStage: Hashable {
    case inProgress
    case finished
    case unsuccessful
}

protocol TransactionDetailsOperationViewData {
    var tokensData: TransactionDetailsTokensViewData { get }
    var statusBanner: TransactionDetailsStatusBannerViewData? { get }
    var infoData: TransactionDetailsInfoSectionViewData? { get }
    var action: TransactionDetailsActionButtonViewData? { get }
}

extension TransactionDetailsOperationViewData {
    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokensData)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let infoData {
            blocks.append(.info(infoData))
        }

        if let action {
            blocks.append(.action(action))
        }

        return blocks
    }
}
