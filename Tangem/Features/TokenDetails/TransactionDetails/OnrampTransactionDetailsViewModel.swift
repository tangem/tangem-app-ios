//
//  OnrampTransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAccounts
import TangemLocalization
import TangemUI

@MainActor
final class OnrampTransactionDetailsViewModel: ObservableObject {
    enum Stage: Hashable {
        case inProgress
        case finished
        case unsuccessful
    }

    struct PaidLeg {
        let amount: String
        let symbol: String
        let fiatPrice: String?
        let flagIconURL: URL?
    }

    struct ReceivedLeg {
        let destinationName: String
        let accountIcon: AccountIconView.ViewData?
        let amount: String
        let symbol: String
        let fiatPrice: String?
        let tokenIconInfo: TokenIconInfo
    }

    let stage: Stage
    let paid: PaidLeg
    let received: ReceivedLeg

    let isReceivedEstimated: Bool

    let statusBanner: TransactionDetailsStatusBannerViewData?
    let provider: TransactionDetailsProvider?
    let rate: String?
    /// Footer button ("Go to provider" / "Go to verification"). Shown for verification / paused states
    let action: TransactionDetailsActionButtonViewData?

    init(
        stage: Stage,
        paid: PaidLeg,
        received: ReceivedLeg,
        isReceivedEstimated: Bool,
        statusBanner: TransactionDetailsStatusBannerViewData? = nil,
        provider: TransactionDetailsProvider? = nil,
        rate: String? = nil,
        action: TransactionDetailsActionButtonViewData? = nil
    ) {
        self.stage = stage
        self.paid = paid
        self.received = received
        self.isReceivedEstimated = isReceivedEstimated
        self.statusBanner = statusBanner
        self.provider = provider
        self.rate = rate
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
        let isUnsuccessful = stage == .unsuccessful

        return TransactionDetailsTokensViewData(
            from: .init(
                // [REDACTED_TODO_COMMENT]
                direction: .init(label: "You paid"),
                icon: .image(url: paid.flagIconURL),
                amountText: paidAmountText,
                fiatText: paid.fiatPrice,
                isAmountStrikethrough: false
            ),
            to: .init(
                direction: .init(
                    label: Localization.commonTo,
                    owner: .init(icon: received.accountIcon, name: received.destinationName)
                ),
                icon: .token(received.tokenIconInfo),
                amountText: receivedAmountText,
                fiatText: isUnsuccessful ? nil : received.fiatPrice,
                isAmountStrikethrough: isUnsuccessful
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

        return rows.isEmpty ? nil : .init(rows: rows)
    }

    /// The paid amount is never signed, in any state.
    private var paidAmountText: String {
        "\(paid.amount) \(paid.symbol)"
    }

    private var receivedAmountText: String {
        let base = "\(received.amount) \(received.symbol)"
        switch stage {
        case .inProgress: return isReceivedEstimated ? "~ \(base)" : base
        case .finished, .unsuccessful: return base
        }
    }
}
