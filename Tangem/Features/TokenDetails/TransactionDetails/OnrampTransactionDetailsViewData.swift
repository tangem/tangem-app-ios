//
//  OnrampTransactionDetailsViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

struct OnrampTransactionDetailsViewData: TransactionDetailsOperationViewData {
    struct PaidLeg {
        let amount: String
        let symbol: String
        let fiatPrice: String?
        let flagIconURL: URL?
        let isFlagLoading: Bool
    }

    struct ReceivedLeg {
        let destination: TransactionDetailsActor
        let amount: String
        let symbol: String
        let fiatPrice: String?
        let tokenIconInfo: TokenIconInfo
    }

    let stage: TransactionDetailsOperationStage
    let paid: PaidLeg
    let received: ReceivedLeg
    let isReceivedEstimated: Bool
    let statusBanner: TransactionDetailsStatusBannerViewData?
    let provider: TransactionDetailsProviderInfo?
    let rate: String?
    /// Footer button ("Go to provider" / "Go to verification"). Shown for verification / paused states
    let action: TransactionDetailsActionButtonViewData?

    var tokensData: TransactionDetailsTokensViewData {
        let isUnsuccessful = stage == .unsuccessful

        return TransactionDetailsTokensViewData(
            from: .init(
                // [REDACTED_TODO_COMMENT]
                direction: .init(label: "You paid", actor: nil),
                icon: paid.isFlagLoading ? .loading : .image(url: paid.flagIconURL),
                amountText: paidAmountText,
                fiatText: paid.fiatPrice,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: Localization.commonTo, actor: received.destination),
                icon: .token(received.tokenIconInfo),
                amountText: receivedAmountText,
                fiatText: isUnsuccessful ? nil : received.fiatPrice,
                isAmountStrikethrough: isUnsuccessful
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

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    /// The paid amount is never signed, in any state.
    private var paidAmountText: String {
        "\(paid.amount) \(paid.symbol)"
    }

    private var receivedAmountText: String {
        let base = "\(received.amount) \(received.symbol)"
        switch stage {
        case .inProgress: return isReceivedEstimated ? "\(AppConstants.tildeSign) \(base)" : base
        case .finished, .unsuccessful: return base
        }
    }
}
