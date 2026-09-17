//
//  PolymarketRedeemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

@MainActor
final class PolymarketRedeemViewModel: ObservableObject, Identifiable {
    @Published private(set) var isClaiming = false
    @Published var alert: AlertBinder?

    private let position: PolymarketPosition
    private let outcome: Outcome
    private let redeemService: PolymarketRedeeming
    private let onClaimed: () -> Void
    private weak var coordinator: PolymarketRedeemRoutable?

    private var claimTask: Task<Void, Never>?

    init?(
        position: PolymarketPosition,
        redeemService: PolymarketRedeeming,
        onClaimed: @escaping () -> Void,
        coordinator: PolymarketRedeemRoutable
    ) {
        guard let outcome = Outcome(position.settlement) else { return nil }

        self.outcome = outcome
        self.position = position
        self.redeemService = redeemService
        self.onClaimed = onClaimed
        self.coordinator = coordinator
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .primaryTapped:
            isActionClaim ? claim() : coordinator?.closeRedeem()
        case .disappeared:
            claimTask?.cancel()
            claimTask = nil
        }
    }
}

// MARK: - View actions

extension PolymarketRedeemViewModel {
    enum ViewAction {
        case primaryTapped
        case disappeared
    }
}

// MARK: - Content

extension PolymarketRedeemViewModel {
    var appearance: StatusScreenAppearance {
        switch outcome {
        case .won: .success
        case .split: .info
        case .lost: .error
        }
    }

    // [REDACTED_TODO_COMMENT]
    var title: String {
        switch outcome {
        case .won: "You Won \(money(position.currentValue))"
        case .split: "Split \(money(position.currentValue))"
        case .lost: "Loss \(money(lostAmount))"
        }
    }

    var description: String? {
        position.endDate.map { PolymarketOrderResultFormatter.resolutionDay($0) }
    }

    // [REDACTED_TODO_COMMENT]
    var actionTitle: String {
        isActionClaim ? "Claim reward" : "Dismiss"
    }

    var isActionClaim: Bool {
        outcome.isClaimable && position.isRedeemable
    }

    // [REDACTED_TODO_COMMENT]
    var footerCaption: String? {
        guard outcome.isClaimable else { return nil }

        return position.isRedeemable
            ? "Funds will be added to your balance"
            : "The payout is not on chain yet. Check back in a few minutes."
    }

    var marketRow: PolymarketOrderMarketRow.Model {
        .make(position: position)
    }

    var investedText: String? {
        guard outcome.isClaimable else { return nil }

        return money(position.initialValue)
    }

    var profit: Profit? {
        guard outcome.isClaimable, position.cashPnl != 0 else { return nil }

        return Profit(
            text: "\(signedMoney(position.cashPnl)) (\(percentFormatter.format(position.pnlRatio, option: .priceChange)))",
            direction: position.cashPnl > 0 ? .positive : .negative
        )
    }

    struct Profit {
        let text: String
        let direction: UtilPriceChange.Direction
    }
}

// MARK: - Claiming

private extension PolymarketRedeemViewModel {
    func claim() {
        guard claimTask == nil else { return }

        isClaiming = true

        claimTask = runTask(in: self) { @MainActor viewModel in
            defer {
                viewModel.isClaiming = false
                viewModel.claimTask = nil
            }

            do {
                _ = try await viewModel.redeemService.claim(
                    conditionId: viewModel.position.conditionId,
                    isNegRisk: viewModel.position.isNegRisk
                )

                guard !Task.isCancelled else { return }

                viewModel.onClaimed()
                viewModel.coordinator?.closeRedeem()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                if case PolymarketRedeemTransactionService.Error.claimUnconfirmed = error {
                    viewModel.onClaimed()
                }

                viewModel.alert = error.alertBinder
            }
        }
    }
}

// MARK: - Outcome

private extension PolymarketRedeemViewModel {
    enum Outcome {
        case won
        case split
        case lost

        init?(_ settlement: PolymarketPositionSettlement?) {
            switch settlement {
            case .won: self = .won
            case .split: self = .split
            case .lost: self = .lost
            case .unknown, .none: return nil
            }
        }

        var isClaimable: Bool {
            switch self {
            case .won, .split: true
            case .lost: false
            }
        }
    }

    var lostAmount: Decimal {
        abs(position.lifetimePnl)
    }
}

// MARK: - Formatting

private extension PolymarketRedeemViewModel {
    var percentFormatter: PercentFormatter { PercentFormatter() }

    func money(_ value: Decimal) -> String {
        PolymarketOrderFormatter.money(value)
    }

    func signedMoney(_ value: Decimal) -> String {
        let amount = money(abs(value))

        return value < 0 ? "-\(amount)" : "+\(amount)"
    }
}
