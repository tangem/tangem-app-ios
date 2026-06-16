//
//  SwapBalanceRestrictionFeatureChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol SwapBalanceRestrictionFeatureChecker {
    func hasSwapTotalBalanceRestriction(for token: SendSourceToken) async throws -> Bool
}

enum SwapBalanceRestrictionFeatureCheckerError: LocalizedError {
    case userWalletNotFound

    var errorDescription: String? {
        switch self {
        case .userWalletNotFound: "User wallet not found"
        }
    }
}

struct CommonSwapBalanceRestrictionFeatureChecker {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
}

// MARK: - SwapBalanceRestrictionFeatureChecker

extension CommonSwapBalanceRestrictionFeatureChecker: SwapBalanceRestrictionFeatureChecker {
    func hasSwapTotalBalanceRestriction(for token: any SendSourceToken) async throws -> Bool {
        guard let userWalletModel = userWalletRepository.models[token.userWalletInfo.id] else {
            throw SwapBalanceRestrictionFeatureCheckerError.userWalletNotFound
        }

        guard userWalletModel.config.hasFeature(.isBalanceRestrictionActive) else {
            return false
        }

        if userWalletRepository.models.count > 1 {
            return false
        }

        let totalBalance = try await {
            // If total is loading
            if userWalletModel.totalBalance.isLoading {
                // Wait until finish state
                return try await userWalletModel.totalBalancePublisher.first { !$0.isLoading }.async()
            }

            return userWalletModel.totalBalance
        }()

        let hasPositiveBalance = totalBalance.hasAnyPositiveBalance

        return !hasPositiveBalance
    }
}
