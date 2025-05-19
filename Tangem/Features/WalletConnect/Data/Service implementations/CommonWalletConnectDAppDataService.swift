//
//  CommonWalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class CommonWalletConnectDAppDataService: WalletConnectDAppDataService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func getDAppData(for uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) async throws -> WalletConnectDApp.DAppData {
        try await walletConnectService.openSession(with: uri, source: source)
    }
}
