//
//  PolymarketReceiveTokenWithdrawNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PolymarketReceiveTokenWithdrawNoticeInteractor {
    @AppStorageCompat(StorageKeys.shownWithdrawalAlerts)
    private var shownWithdrawalAlerts: [String: Bool] = [:]

    init() {}

    init(store: UserDefaults) {
        _shownWithdrawalAlerts = AppStorageCompat(
            wrappedValue: [:],
            StorageKeys.shownWithdrawalAlerts,
            store: store
        )
    }
}

// MARK: - ReceiveTokenWithdrawNoticeInteractor protocol conformance

extension PolymarketReceiveTokenWithdrawNoticeInteractor: ReceiveTokenWithdrawNoticeInteractor {
    func shouldShowWithdrawalAlert(for tokenItem: TokenItem) -> Bool {
        let key = Self.noticeKey(for: tokenItem)
        let shown = shownWithdrawalAlerts[key] ?? false
        shownWithdrawalAlerts[key] = true

        return !shown
    }

    func markWithdrawalAlertShown(for tokenItem: TokenItem) {
        shownWithdrawalAlerts[Self.noticeKey(for: tokenItem)] = true
    }
}

// MARK: - Private implementation

private extension PolymarketReceiveTokenWithdrawNoticeInteractor {
    enum StorageKeys: String, RawRepresentable {
        case shownWithdrawalAlerts = "polymarket_deposit_shown_withdrawal_alerts"
    }
}
