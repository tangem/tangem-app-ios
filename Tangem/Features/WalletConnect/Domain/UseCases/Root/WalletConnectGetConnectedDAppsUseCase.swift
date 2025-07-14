//
//  WalletConnectGetConnectedDAppsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectGetConnectedDAppsUseCase {
    private let repository: any WalletConnectConnectedDAppRepository

    init(repository: some WalletConnectConnectedDAppRepository) {
        self.repository = repository
    }

    func callAsFunction() async -> AsyncStream<[WalletConnectConnectedDApp]> {
        await repository.makeDAppsStream()
    }

    func callAsFunction() async throws(WalletConnectDAppPersistenceError) -> [WalletConnectConnectedDApp] {
        try await repository.getAllDApps()
    }
}
