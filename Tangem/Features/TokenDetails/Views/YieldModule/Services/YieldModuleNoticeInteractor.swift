//
//  YieldModuleNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldModuleNoticeInteractor {
    @AppStorageCompat(StorageKey.shownYieldModuleAlerts)
    private var shownYieldModuleAlerts: [String: Bool] = [:]

    // MARK: - Public Implementation

    /// Returns true only on the first show if the stored value is `false`.
    /// If the value is `true` or missing (`nil`), returns false.
    /// If the value is `false` marks the alert as shown
    func shouldShowYieldModuleAlert(for tokenItem: TokenItem) -> Bool {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_INFO]
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return false
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)

        guard shownYieldModuleAlerts[key] == false else {
            return false
        }

        shownYieldModuleAlerts[key] = true
        return true
    }

    func markWithdrawalAlertShouldShow(for tokenItem: TokenItem) {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)
        shownYieldModuleAlerts[key] = false
    }

    // MARK: - Private Implementation

    private func yieldKey(contractAddress: String, networkId: String) -> String {
        "yield_receive_shown_withdrawal_token_\(contractAddress)_\(networkId)"
    }
}

extension YieldModuleNoticeInteractor {
    private enum StorageKey: String, RawRepresentable {
        case shownYieldModuleAlerts = "yield_receive_shown_withdrawal_token_alerts"
    }
}
