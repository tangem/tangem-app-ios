//
//  YieldModuleNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldModuleNoticeInteractor {
    @AppStorageCompat(StorageKey.shownYieldModuleAlert)
    private var shownYieldModuleAlert: [String: Bool] = [:]

    // MARK: - Public Implementation

    /// Returns true only on the first show if the stored value is `false`.
    /// If the value is `true` or missing (`nil`), returns false.
    /// If the value is `false` marks the alert as shown
    func shouldShowYieldModuleAlert(for tokenItem: TokenItem) -> Bool {
        // [REDACTED_TODO_COMMENT]
        // but it's kept here for the second iteration.
        return false

//        guard case .token(let token, let blockchainNetwork) = tokenItem else {
//            return false
//        }
//
//        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)
//
//        guard shownYieldModuleAlert[key] == false else {
//            return false
//        }
//
//        shownYieldModuleAlert[key] = true
//        return true
    }

    func markWithdrawalAlertShouldShow(for tokenItem: TokenItem) {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)
        shownYieldModuleAlert[key] = false
    }

    func deleteWithdrawalAlert(for tokenItem: TokenItem) {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)
        shownYieldModuleAlert.removeValue(forKey: key)
    }

    // MARK: - Private Implementation

    private func yieldKey(contractAddress: String, networkId: String) -> String {
        "yield_receive_shown_withdrawal_token_\(contractAddress)_\(networkId)"
    }
}

extension YieldModuleNoticeInteractor {
    private enum StorageKey: String, RawRepresentable {
        case shownYieldModuleAlert = "yield_receive_shown_token_alerts"
    }
}
