//
//  WalletModelReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

struct WalletModelReceivingRestrictionsProvider: ReceivingRestrictionsProvider {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    var isRestrictionKnown: Bool {
        guard hasAssetRequirements else {
            return true
        }

        switch walletModel.state {
        case .loaded, .noAccount:
            return true
        case .created, .loading, .failed:
            return false
        }
    }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction? {
        try await loadRestrictionsDataIfNeeded()

        if case .requiresTrustline = walletModel.assetRequirementsManager?.requirementsCondition(for: walletModel.tokenItem.amountType) {
            return .requiresTrustline
        }

        // Not a hard restriction: topping up a wallet with an incomplete backup is confirmed at the `Swap` tap.
        if !userWalletInfo.backupState.isValid {
            return .incompleteBackup(userWalletInfo)
        }

        switch walletModel.state {
        case .noAccount(_, let amountToCreateAccount) where expectAmount < amountToCreateAccount:
            return .notEnoughReceivedAmount(minAmount: amountToCreateAccount)
        default:
            return .none
        }
    }

    private func loadRestrictionsDataIfNeeded() async throws {
        guard hasAssetRequirements else {
            return
        }

        switch walletModel.state {
        case .loaded, .noAccount:
            return
        case .loading:
            break
        case .created, .failed:
            await walletModel.update(silent: true, options: .balances)
        }

        if !isSettled(walletModel.state) {
            _ = try await walletModel.statePublisher
                .filter { isSettled($0) }
                .async()
        }

        guard isRestrictionKnown else {
            throw ReceivingRestrictionsError.restrictionsDataUnavailable
        }
    }

    private var hasAssetRequirements: Bool {
        walletModel.assetRequirementsManager != nil
    }

    private func isSettled(_ state: WalletModelState) -> Bool {
        switch state {
        case .loaded, .noAccount, .failed:
            true
        case .created, .loading:
            false
        }
    }
}
