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
        let symbol: String
        let tokenIconInfo: TokenIconInfo
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
                icon: .token(source.tokenIconInfo),
                amountText: sourceAmountText,
                fiatText: nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: destinationLabel, actor: nil),
                icon: .token(destination.tokenIconInfo),
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
        case .inProgress: return isDestinationEstimated ? "\(AppConstants.tildeSign) \(base)" : base
        case .finished: return "+ \(base)"
        case .unsuccessful: return base
        }
    }
}
