//
//  ReceiveTransactionDetailsViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct ReceiveTransactionDetailsViewData {
    let tokens: TransactionDetailsTokensViewData

    /// Shown for in-progress / just-received states; omitted for a plain confirmed receive.
    let statusBanner: TransactionDetailsStatusBannerViewData?

    /// The sender ("From"). Absent when the counterparty can't be resolved.
    let sender: TransactionDetailsAddressViewData?

    init(
        tokens: TransactionDetailsTokensViewData,
        statusBanner: TransactionDetailsStatusBannerViewData? = nil,
        sender: TransactionDetailsAddressViewData? = nil
    ) {
        self.tokens = tokens
        self.statusBanner = statusBanner
        self.sender = sender
    }

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokens)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let sender {
            blocks.append(.counterparty(sender))
        }

        return blocks
    }
}
