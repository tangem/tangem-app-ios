//
//  SendTransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class SendTransactionDetailsViewModel: ObservableObject {
    let tokens: TransactionDetailsTokensViewData

    /// Shown for in-progress / failed states; omitted for a plain confirmed send.
    let statusBanner: TransactionDetailsStatusBannerViewData?

    /// The destination ("Recipient"). Absent when the counterparty can't be resolved.
    let recipient: TransactionDetailsAddressViewData?

    /// Network fee and any other key/value rows.
    let info: TransactionDetailsInfoSectionViewData?

    /// Footer button (e.g. retry on failure). Stretches the sheet to the bottom when present.
    let action: TransactionDetailsActionButtonViewData?

    init(
        tokens: TransactionDetailsTokensViewData,
        statusBanner: TransactionDetailsStatusBannerViewData? = nil,
        recipient: TransactionDetailsAddressViewData? = nil,
        info: TransactionDetailsInfoSectionViewData? = nil,
        action: TransactionDetailsActionButtonViewData? = nil
    ) {
        self.tokens = tokens
        self.statusBanner = statusBanner
        self.recipient = recipient
        self.info = info
        self.action = action
    }

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokens)]

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let recipient {
            blocks.append(.counterparty(recipient))
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
