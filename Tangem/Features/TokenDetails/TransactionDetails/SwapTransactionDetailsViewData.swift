//
//  SwapTransactionDetailsViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

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
    let provider: TransactionDetailsProvider?
    let rate: String?
    let networkFee: String?
    /// Footer button ("Go to provider" / "Go to verification"). Shown for verification / paused / long-running states
    let action: TransactionDetailsActionButtonViewData?

    init(
        stage: TransactionDetailsOperationStage,
        source: Leg,
        destination: Leg,
        isDestinationEstimated: Bool,
        statusBanner: TransactionDetailsStatusBannerViewData? = nil,
        provider: TransactionDetailsProvider? = nil,
        rate: String? = nil,
        networkFee: String? = nil,
        action: TransactionDetailsActionButtonViewData? = nil
    ) {
        self.stage = stage
        self.source = source
        self.destination = destination
        self.isDestinationEstimated = isDestinationEstimated
        self.statusBanner = statusBanner
        self.provider = provider
        self.rate = rate
        self.networkFee = networkFee
        self.action = action
    }

    var tokensData: TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            from: .init(
                direction: .init(label: Localization.swappingFromTitleV2),
                icon: icon(for: source),
                amountText: sourceAmountText,
                fiatText: nil,
                isSymbolLoading: source.symbol == nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: destinationLabel),
                icon: icon(for: destination),
                amountText: destinationAmountText,
                fiatText: nil,
                isSymbolLoading: destination.symbol == nil,
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
            rows.append(.init(title: "Rate", content: .text(rate)))
        }

        if let networkFee {
            rows.append(.init(title: Localization.commonNetworkFeeTitle, content: .text(networkFee)))
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

    private var sourceAmountText: String {
        amountText(prefix: "−", leg: source)
    }

    private var destinationAmountText: String {
        let prefix: String? = switch stage {
        case .inProgress: isDestinationEstimated ? "~" : nil
        case .finished: "+"
        case .unsuccessful: nil
        }
        return amountText(prefix: prefix, leg: destination)
    }

    private func amountText(prefix: String?, leg: Leg) -> String {
        [prefix, leg.amount, leg.symbol].compactMap { $0 }.joined(separator: " ")
    }
}
