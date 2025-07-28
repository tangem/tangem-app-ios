//
//  WalletConnectExtendConnectedDAppsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectExtendConnectedDAppsUseCase {
    private let sessionsExtender: WalletConnectDAppSessionsExtender

    init(sessionsExtender: WalletConnectDAppSessionsExtender) {
        self.sessionsExtender = sessionsExtender
    }

    func callAsFunction() async {
        await sessionsExtender.extendConnectedDAppSessionsIfNeeded()
    }
}
