//
//  TransactionDetailsOnrampViewData.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI

struct TransactionDetailsOnrampViewData: TransactionDetailsOperationViewData {
    struct PaidLeg {
        let amount: String
        let symbol: String
        let flagIconURL: URL?
        let isFlagLoading: Bool
    }

    struct ReceivedLeg {
        let destination: TransactionDetailsActor
        /// The delivered amount, falling back to the one the provider promised. `nil` when neither is known.
        let amount: String?
        let symbol: String
        let tokenIconInfo: TokenIconInfo
    }

    let stage: TransactionDetailsOperationStage
    let paid: PaidLeg
    let received: ReceivedLeg
    let statusBanner: TransactionDetailsStatusBannerViewData?
    let provider: TransactionDetailsProviderInfo?
    let rate: String?
    /// Footer button ("Go to provider" / "Go to verification"). Shown for verification / paused / unsuccessful states
    let action: TransactionDetailsActionButtonViewData?

    var tokensData: TransactionDetailsTokensViewData {
        TransactionDetailsTokensViewData(
            from: .init(
                direction: .init(label: Localization.txHistoryYouPaid, actor: nil),
                icon: paid.isFlagLoading ? .loading : .image(url: paid.flagIconURL),
                amountText: paidAmountText,
                fiatText: nil,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(label: Localization.commonTo, actor: received.destination),
                icon: .token(received.tokenIconInfo),
                amountText: receivedAmountText,
                fiatText: nil,
                isAmountStrikethrough: stage == .unsuccessful && received.amount != nil
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

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    /// The paid amount is never signed, in any state.
    private var paidAmountText: String {
        TransactionDetailsAmountTextBuilder.build(paid.amount, symbol: paid.symbol) ?? BalanceFormatter.defaultEmptyBalanceString
    }

    private var receivedAmountText: String {
        TransactionDetailsAmountTextBuilder.build(received.amount, symbol: received.symbol, sign: receivedPrefix)
            ?? BalanceFormatter.defaultEmptyBalanceString
    }

    /// Mirrors the history row's sign, which keys off the same stage — the two surfaces must not disagree
    /// about whether the figure is an estimate or a delivery.
    private var receivedPrefix: String? {
        switch stage {
        case .inProgress: AppConstants.tildeSign
        case .finished: AppConstants.plusSign
        case .unsuccessful: nil
        }
    }
}
