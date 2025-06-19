//
//  ReownWalletConnectDisconnectDAppService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class ReownWalletConnectDisconnectDAppService: WalletConnectDisconnectDAppService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func disconnect(with sessionTopic: String) async throws {
        try await walletConnectService.disconnectSession(withTopic: sessionTopic)
    }
}
