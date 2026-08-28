//
//  WithdrawHubViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemUIUtils

final class WithdrawHubViewModel: ObservableObject {
    @Published var alert: AlertBinder?
    @Published private(set) var isWithinPortfolioLoading = false

    private let withdrawFlowResolver: TangemPayWithdrawFlowResolver
    private let output: (Output) -> Void

    private var withinPortfolioTask: Task<Void, Error>?

    init(
        withdrawFlowResolver: TangemPayWithdrawFlowResolver,
        output: @escaping (Output) -> Void
    ) {
        self.withdrawFlowResolver = withdrawFlowResolver
        self.output = output
    }

    func onCloseTap() {
        output(.close)
    }

    func onWithinPortfolioTap() {
        withinPortfolioTask?.cancel()
        withinPortfolioTask = runWithDelayedLoading(
            onLongRunning: { @MainActor [weak self] in
                self?.isWithinPortfolioLoading = true
            },
            onCancel: { [weak self] in
                guard let self else { return }

                Task { @MainActor in
                    self.isWithinPortfolioLoading = false
                }
            },
            operation: { @MainActor [weak self, withdrawFlowResolver] in
                defer { self?.isWithinPortfolioLoading = false }

                do {
                    let outcome = try await withdrawFlowResolver.resolve()

                    guard !Task.isCancelled, let self else { return }

                    handle(outcome)
                } catch is CancellationError {
                    // Do nothing
                } catch {
                    self?.alert = error.alertBinder
                }
            }
        )
    }

    private func handle(_ outcome: TangemPayWithdrawFlowResolver.Outcome) {
        switch outcome {
        case .swap(let swapParameters):
            output(.withdrawNote(swapParameters))

        case .pendingWithdrawOrder:
            output(.withdrawInProgress)

        case .unavailable:
            output(.noDepositAddress)

        case .restricted(let restriction):
            alert = TokenActionAvailabilityAlertBuilder().alert(for: restriction)
        }
    }
}

// MARK: - Output

extension WithdrawHubViewModel {
    enum Output {
        case withdrawNote(PredefinedSwapParameters)
        case withdrawInProgress
        case noDepositAddress
        case close
    }
}
