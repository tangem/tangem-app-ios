//
//  TransactionDetailsOperationViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Lifecycle stage shared by swap and onramp details — drives amount prefixes, strikethrough and titles.
enum TransactionDetailsOperationStage: Hashable {
    case inProgress
    case finished
    case unsuccessful
}

/// Common shape of a two-leg operation details model (swap / onramp). The block layout is identical
/// for both, so it's assembled once here; each operation only provides its own tokens / info content.
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
