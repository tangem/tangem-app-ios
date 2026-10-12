//
//  WalletConnectDisconnectDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectDisconnectDAppUseCase {
    private let disconnectDAppService: any WalletConnectDisconnectDAppService
    private let connectedDAppRepository: any WalletConnectConnectedDAppRepository

    init(disconnectDAppService: some WalletConnectDisconnectDAppService, connectedDAppRepository: some WalletConnectConnectedDAppRepository) {
        self.disconnectDAppService = disconnectDAppService
        self.connectedDAppRepository = connectedDAppRepository
    }

    // [REDACTED_TODO_COMMENT]
    func callAsFunction(_ connectedDApp: WalletConnectConnectedDApp) async throws {
        async let disconnectDApp: Void = try await disconnectDAppService.disconnect(with: connectedDApp.session.topic)
        async let removeDAppFromCache: Void = try await connectedDAppRepository.deleteDApp(with: connectedDApp.session.topic)

        try? await disconnectDApp
        try await removeDAppFromCache
    }
}
