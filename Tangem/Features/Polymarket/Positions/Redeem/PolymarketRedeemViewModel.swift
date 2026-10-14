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
    private let signingButtonType: SigningActionButtonViewType
    private let onClaimed: (PolymarketPosition?) -> Void
    private weak var coordinator: PolymarketRedeemRoutable?

    private var claimTask: Task<Void, Never>?

    init(
        position: PolymarketPosition,
        redeemService: PolymarketRedeeming,
        signingButtonType: SigningActionButtonViewType,
        onClaimed: @escaping (PolymarketPosition?) -> Void,
        coordinator: PolymarketRedeemRoutable
    ) {
        outcome = Outcome(position.settlement)
        self.position = position
        self.redeemService = redeemService
        self.signingButtonType = signingButtonType
        self.onClaimed = onClaimed
        self.coordinator = coordinator
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .performPrimaryAction:
            isActionClaim ? claim() : coordinator?.closeRedeem()
        case .close:
            guard !isClaiming else { return }

            coordinator?.closeRedeem()
        case .onDisappear:
            claimTask?.cancel()
            claimTask = nil
        }
    }
}

// MARK: - View actions

extension PolymarketRedeemViewModel {
    enum ViewAction {
        case performPrimaryAction
        case close
        case onDisappear
    }
}

// MARK: - Content

extension PolymarketRedeemViewModel {
    var appearance: StatusScreenAppearance {
        switch outcome {
        case .won: .success
        case .split, .undetermined: .info
        case .lost: .error
        }
    }

    var title: String {
        switch outcome {
        case .won: Localization.predictionPositionResultWonTitle(money(position.currentValue))
        case .split: Localization.predictionPositionResultSplitTitle(money(position.currentValue))
        case .lost: Localization.predictionPositionResultLossTitle(money(lostAmount))
        // [REDACTED_TODO_COMMENT]
        case .undetermined: "Ready to claim \(money(position.currentValue))"
        }
    }

    var description: String? {
        position.endDate.map { PolymarketOrderResultFormatter.resolutionDay($0) }
    }

    var actionTitle: String {
        guard isActionClaim else { return Localization.predictionPositionResultDismissAction }

        return outcome.paysOut ? Localization.predictionPositionResultClaimAction : Localization.predictionPositionResultCloseAction
    }

    var actionSigningType: SigningActionButtonViewType? {
        isActionClaim ? signingButtonType : nil
    }

    var isActionClaim: Bool {
        position.isRedeemable
    }

    var footerCaption: String? {
        guard outcome.paysOut else { return nil }

        return position.isRedeemable
            ? Localization.predictionPositionResultBalanceNote
            : Localization.predictionPositionResultPayoutPendingNote
    }

    var marketRow: PolymarketOrderMarketRow.Model {
        .make(position: position)
    }

    var investedText: String? {
        guard outcome.paysOut else { return nil }

        return money(position.initialValue)
    }

    var profit: Profit? {
        let displayed = PolymarketOrderFormatter.displayedMoney(position.cashPnl)

        guard outcome.paysOut, displayed != 0 else { return nil }

        return Profit(
            text: "\(money(abs(displayed))) (\(Self.percentFormatter.format(position.pnlRatio, option: .priceChange)))",
            direction: displayed > 0 ? .positive : .negative
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

                viewModel.onClaimed(viewModel.position)
                viewModel.coordinator?.closeRedeem()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                viewModel.onClaimed(nil)
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
        case undetermined

        init(_ settlement: PolymarketPositionSettlement?) {
            switch settlement {
            case .won: self = .won
            case .split: self = .split
            case .lost: self = .lost
            case .unknown, .none: self = .undetermined
            }
        }

        var paysOut: Bool {
            switch self {
            case .won, .split: true
            case .lost, .undetermined: false
            }
        }
    }

    var lostAmount: Decimal {
        abs(position.lifetimePnl)
    }
}

// MARK: - Formatting

private extension PolymarketRedeemViewModel {
    static let percentFormatter = PercentFormatter()

    func money(_ value: Decimal) -> String {
        PolymarketOrderFormatter.money(value)
    }
}
