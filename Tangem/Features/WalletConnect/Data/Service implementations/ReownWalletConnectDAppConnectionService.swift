//
//  ReownWalletConnectDAppConnectionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

final class ReownWalletConnectDAppConnectionService: WalletConnectDAppConnectionService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    // [REDACTED_TODO_COMMENT]
    func connectDApp(with request: WalletConnectDAppConnectionRequest, _ userWalletID: String) async throws {
        let reownNamespaces = WalletConnectSessionNamespaceMapper.mapFromDomain(request.namespaces)
        try await walletConnectService.acceptSessionProposal(with: request.proposalID, namespaces: reownNamespaces, userWalletID)
    }

    func disconnectDApp(with request: WalletConnectDAppConnectionRequest) async throws {
        // [REDACTED_TODO_COMMENT]
    }
}
