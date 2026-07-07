//
//  TransactionDetailsSendReceiveViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TransactionDetailsSendReceiveViewData {
    let tokens: TransactionDetailsTokensViewData

    /// Shown for in-progress / failed / just-received states; omitted for a plain confirmed transfer.
    let statusBanner: TransactionDetailsStatusBannerViewData?

    /// The counterparty — recipient ("Recipient") for send, sender ("From") for receive; the role is
    /// carried by its label. Absent when it can't be resolved.
    let counterparty: TransactionDetailsAddressViewData?

    /// Network fee and any other key/value rows (send only).
    let info: TransactionDetailsInfoSectionViewData?

    /// Footer button, e.g. retry on failure (send only). Stretches the sheet to the bottom when present.
    let action: TransactionDetailsActionButtonViewData?

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokens)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let counterparty {
            blocks.append(.counterparty(counterparty))
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
