//
//  YieldModuleNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class YieldModuleNoticeInteractor {
    @AppStorageCompat(StorageKey.shownYieldModuleReceiveAlert)
    private var shownYieldModuleReceiveAlert: [String: Bool] = [:]

    @AppStorageCompat(StorageKey.shownYieldModuleSendAlert)
    private var shownYieldModuleSendAlert: [String: Bool] = [:]

    // MARK: - Public Implementation

    /// Returns true only on the first show if the stored value is `false`.
    /// If the value is `true` or missing (`nil`), returns false.
    /// If the value is `false` marks the alert as shown
    func shouldShowYieldModuleReceiveAlert(for tokenItem: TokenItem) -> Bool {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return false
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)

        guard shownYieldModuleReceiveAlert[key] == false else {
            return false
        }

        shownYieldModuleReceiveAlert[key] = true
        return true
    }

    func shouldShowYieldModuleSendAlert(for tokenItem: TokenItem) -> Bool {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return false
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)

        guard shownYieldModuleSendAlert[key] == false else {
            return false
        }

        shownYieldModuleSendAlert[key] = true
        return true
    }

    func markWithdrawalAlertShouldShow(for tokenItem: TokenItem) {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return
        }

        let key = yieldKey(contractAddress: token.contractAddress, networkId: blockchainNetwork.blockchain.networkId)
        shownYieldModuleReceiveAlert[key] = false
        shownYieldModuleSendAlert[key] = false
    }

    // MARK: - Private Implementation

    private func yieldKey(contractAddress: String, networkId: String) -> String {
        "yield_receive_shown_withdrawal_token_\(contractAddress)_\(networkId)"
    }
}

extension YieldModuleNoticeInteractor {
    private enum StorageKey: String, RawRepresentable {
        case shownYieldModuleReceiveAlert = "yield_receive_shown_receive_token_alerts"
        case shownYieldModuleSendAlert = "yield_receive_shown_send_token_alerts"
    }
}
