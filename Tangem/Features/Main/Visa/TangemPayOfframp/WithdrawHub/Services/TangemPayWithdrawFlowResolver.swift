//
//  TangemPayWithdrawFlowResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayWithdrawFlowResolver {
    private let fundingFlowBuilder: TangemPayFundingFlowBuilder
    private let withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider

    init(
        fundingFlowBuilder: TangemPayFundingFlowBuilder,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider
    ) {
        self.fundingFlowBuilder = fundingFlowBuilder
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
    }

    @MainActor
    func resolve() async throws -> Outcome {
        try await resolve(await fundingFlowBuilder.withdraw())
    }

    @MainActor
    func resolve(repeating target: TangemPayRecentOperationTarget) async throws -> Outcome {
        try await resolve(await fundingFlowBuilder.withdraw(repeating: target))
    }

    @MainActor
    private func resolve(_ resolution: TangemPayFundingFlowBuilder.WithdrawResolution) async throws -> Outcome {
        switch resolution {
        case .unavailable:
            return .unavailable

        case .parameters(let swapParameters):
            let restriction = try await withdrawAvailabilityProvider.restriction()

            try Task.checkCancellation()

            switch restriction {
            case .none, .zeroWalletBalance:
                return .swap(swapParameters)
            case .hasPendingWithdrawOrder:
                return .pendingWithdrawOrder
            case .some(let restriction):
                return .restricted(restriction)
            }
        }
    }
}

// MARK: - Outcome

extension TangemPayWithdrawFlowResolver {
    enum Outcome {
        case swap(PredefinedSwapParameters)
        case unavailable
        case pendingWithdrawOrder
        case restricted(SendingRestrictions)
    }
}
