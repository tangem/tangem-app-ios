//
//  SwapTransactionDetailsViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUI

struct SwapTransactionDetailsViewData: TransactionDetailsOperationViewData {
    struct Leg {
        let amount: String
        let symbol: String?
        let tokenIconInfo: TokenIconInfo?
    }

    let stage: TransactionDetailsOperationStage
    let source: Leg
    let destination: Leg
    let isDestinationEstimated: Bool
    let statusBanner: TransactionDetailsStatusBannerViewData?
    let provider: TransactionDetailsProviderInfo?
    let rate: String?
    let networkFee: String?
    /// Footer button ("Go to provider" / "Go to verification"). Shown for verification / paused / long-running states
    let action: TransactionDetailsActionButtonViewData?

    var tokensData: TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            from: .init(
                direction: .init(label: Localization.swappingFromTitleV2, actor: nil),
                icon: icon(for: source),
                amountText: sourceAmountText,
                fiatText: nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: destinationLabel, actor: nil),
                icon: icon(for: destination),
                amountText: destinationAmountText,
                fiatText: nil,
                isAmountStrikethrough: stage == .unsuccessful
            )
        )
    }

    var infoData: TransactionDetailsInfoSectionViewData? {
        var rows: [TransactionDetailsInfoSectionViewData.Row] = []

        if let provider {
            rows.append(provider.infoRow)
        }

        if let rate {
            // [REDACTED_TODO_COMMENT]
            rows.append(.init(id: "rate", title: "Rate", content: .text(rate)))
        }

        if let networkFee {
            rows.append(.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .text(networkFee)))
        }

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    private func icon(for leg: Leg) -> TransactionDetailsTokensViewData.Leg.Icon {
        leg.tokenIconInfo.map { .token($0) } ?? .loading
    }

    private var destinationLabel: String {
        switch stage {
        case .inProgress: Localization.expressEstimatedAmount
        case .finished, .unsuccessful: Localization.swappingToTitle
        }
    }

    private var sourceAmountText: String? {
        amountText(prefix: String.minusSign, leg: source)
    }

    private var destinationAmountText: String? {
        let prefix: String? = switch stage {
        case .inProgress: isDestinationEstimated ? AppConstants.tildeSign : nil
        case .finished: String.plusSign
        case .unsuccessful: nil
        }
        return amountText(prefix: prefix, leg: destination)
    }

    /// The amount needs both a number and a resolved ticker — without either it's `nil` and the view
    /// hides it, so we never render a partial value like "+ETH" or "+100". The prefix (sign / "~") is an
    /// optional decoration: a leg without one (e.g. failed) still shows its amount unsigned.
    private func amountText(prefix: String?, leg: Leg) -> String? {
        guard
            let amount = leg.amount.nilIfEmpty,
            let symbol = leg.symbol?.nilIfEmpty
        else {
            return nil
        }

        let value = "\(amount) \(symbol)"

        guard let prefix = prefix?.nilIfEmpty else {
            return value
        }
        // [REDACTED_TODO_COMMENT]
        return "\(prefix) \(value)"
    }
}
