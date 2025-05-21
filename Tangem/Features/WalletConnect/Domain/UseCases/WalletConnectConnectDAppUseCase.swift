//
//  WalletConnectConnectDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class WalletConnectConnectDAppUseCase {
    private let dAppConnectionService: any WalletConnectDAppConnectionService

    init(dAppConnectionService: some WalletConnectDAppConnectionService) {
        self.dAppConnectionService = dAppConnectionService
    }

    func callAsFunction(_ request: WalletConnectDAppConnectionRequest) async throws {
        try await dAppConnectionService.connectDApp(with: request)
    }
}
