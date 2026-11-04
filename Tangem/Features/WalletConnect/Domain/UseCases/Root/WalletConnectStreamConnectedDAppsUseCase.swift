//
//  WalletConnectStreamConnectedDAppsUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct WalletConnectStreamConnectedDAppsUseCase {
    private let repository: any WalletConnectConnectedDAppRepository

    init(repository: some WalletConnectConnectedDAppRepository) {
        self.repository = repository
    }

    func callAsFunction() async -> AsyncStream<[WalletConnectConnectedDApp]> {
        await repository.makeDAppsStream()
    }
}
