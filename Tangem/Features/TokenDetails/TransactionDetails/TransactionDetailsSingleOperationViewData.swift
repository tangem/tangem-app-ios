//
//  TransactionDetailsSingleOperationViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A single-token operation: send / receive / staking / approve / fee / generic "other". The operation
/// kind is conveyed by the header (title + icon); the sheet body composes the shared blocks.
struct TransactionDetailsSingleOperationViewData {
    /// The main token amount block shown at the top. `nil` for operations without an amount (e.g. the generic "other" section).
    let tokens: TransactionDetailsTokensViewData?

    /// Shown for in-progress / failed / just-received states; omitted for a plain confirmed operation.
    let statusBanner: TransactionDetailsStatusBannerViewData?

    /// The amount this operation was charged against (e.g. the fee's "For sending 120.03 USDT"). Absent otherwise.
    let principalAmount: TransactionDetailsPrincipalAmountViewData?

    /// The counterparty — recipient / sender / validator / spender; the role is carried by its label.
    let counterparty: TransactionDetailsAddressViewData?

    /// Key/value rows (network fee, validator, gas price/used, provider, rate, …).
    let info: TransactionDetailsInfoSectionViewData?

    /// Footer button, e.g. retry on failure. Stretches the sheet to the bottom when present.
    let action: TransactionDetailsActionButtonViewData?

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = []

        if let tokens {
            blocks.append(.tokens(tokens))
        }

        if let statusBanner {
            blocks.append(.statusBanner(statusBanner))
        }

        if let principalAmount {
            blocks.append(.principalAmount(principalAmount))
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
