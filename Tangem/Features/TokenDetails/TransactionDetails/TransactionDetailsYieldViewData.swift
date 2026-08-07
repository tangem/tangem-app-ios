//
//  TransactionDetailsYieldViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TransactionDetailsYieldViewData {
    let tokens: TransactionDetailsYieldTokensViewData
    let statusBanner: TransactionDetailsStatusBannerViewData?
    let info: TransactionDetailsInfoSectionViewData?
    let action: TransactionDetailsActionButtonViewData?

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.yieldTokens(tokens)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let info {
            blocks.append(.info(info))
        }

        if let action {
            blocks.append(.action(action))
        }

        return blocks
    }
}
