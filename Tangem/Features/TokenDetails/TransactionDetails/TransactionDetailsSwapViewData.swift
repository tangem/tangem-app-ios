//
//  TransactionDetailsSwapViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import TangemUI

struct TransactionDetailsSwapViewData: TransactionDetailsOperationViewData {
    struct Leg {
        let amount: String
        let symbol: String?
        let tokenIconInfo: TokenIconInfo?
        let actor: TransactionDetailsActor?
    }

    struct RatingTransaction {
        let transactionId: String
        let providerId: String
        let providerName: String?
        let txUrl: String?
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
    let ratingTransaction: RatingTransaction?

    var tokensData: TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            from: .init(
                direction: .init(
                    label: source.actor == nil ? Localization.swappingFromTitleV2 : Localization.commonFrom,
                    actor: source.actor
                ),
                icon: icon(for: source),
                amountText: sourceAmountText,
                fiatText: nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(
                    label: destination.actor == nil ? Localization.swappingToTitle : Localization.commonTo,
                    actor: destination.actor
                ),
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
            rows.append(.init(id: "rate", title: Localization.commonRate, content: .text(rate)))
        }

        if let networkFee {
            rows.append(.init(id: "networkFee", title: Localization.commonNetworkFeeTitle, content: .sensitiveText(networkFee)))
        }

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    private func icon(for leg: Leg) -> TransactionDetailsTokensViewData.Leg.Icon {
        leg.tokenIconInfo.map { .token($0) } ?? .loading
    }

    private var sourceAmountText: String? {
        amountText(prefix: AppConstants.minusSign, leg: source)
    }

    private var destinationAmountText: String? {
        let prefix: String? = switch stage {
        case .inProgress: isDestinationEstimated ? AppConstants.tildeSign : nil
        case .finished: AppConstants.plusSign
        case .unsuccessful: nil
        }
        return amountText(prefix: prefix, leg: destination)
    }

    /// The amount needs both a number and a resolved ticker — without either it's `nil` and the view
    /// hides it, so we never render a partial value like "+ETH" or "+100". The prefix (sign / "~") is an
    /// optional decoration: a leg without one (e.g. failed) still shows its amount unsigned.
    private func amountText(prefix: String?, leg: Leg) -> String? {
        guard let symbol = leg.symbol?.trimmed().nilIfEmpty else {
            return nil
        }

        return TransactionDetailsAmountTextBuilder.build(leg.amount, symbol: symbol, sign: prefix)
    }
}
