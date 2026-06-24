//
//  SwapTransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemUI

@MainActor
final class SwapTransactionDetailsViewModel: ObservableObject {
    enum Stage: Hashable {
        case inProgress
        case finished
        case unsuccessful
    }

    struct Leg {
        let amount: String
        let symbol: String
        let tokenIconInfo: TokenIconInfo
    }

    let stage: Stage
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
        stage: Stage,
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

    var blocks: [TransactionDetailsBlock] {
        var blocks: [TransactionDetailsBlock] = [.tokens(tokensData)]

        if stage != .finished, let statusBanner {
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

    private var tokensData: TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            from: .init(
                direction: .init(label: Localization.swappingFromTitleV2),
                icon: .token(source.tokenIconInfo),
                amountText: sourceAmountText,
                fiatText: nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: destinationLabel),
                icon: .token(destination.tokenIconInfo),
                amountText: destinationAmountText,
                fiatText: nil,
                isAmountStrikethrough: stage == .unsuccessful
            )
        )
    }

    private var infoData: TransactionDetailsInfoSectionViewData? {
        var rows: [TransactionDetailsInfoSectionViewData.Row] = []

        if let provider {
            rows.append(provider.infoRow)
        }

        if let rate {
            // [REDACTED_TODO_COMMENT]
            rows.append(.init(id: "rate", title: "Rate", content: .text(rate)))
        }

        if let networkFee {
            rows.append(.init(id: "fee", title: Localization.commonNetworkFeeTitle, content: .text(networkFee)))
        }

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    private var destinationLabel: String {
        switch stage {
        case .inProgress: Localization.expressEstimatedAmount
        case .finished, .unsuccessful: Localization.swappingToTitle
        }
    }

    private var sourceAmountText: String {
        "− \(source.amount) \(source.symbol)"
    }

    private var destinationAmountText: String {
        let base = "\(destination.amount) \(destination.symbol)"
        switch stage {
        case .inProgress: return isDestinationEstimated ? "~ \(base)" : base
        case .finished: return "+ \(base)"
        case .unsuccessful: return base
        }
    }
}
