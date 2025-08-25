//
//  WalletConnectPersistConnectedDAppUseCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import enum BlockchainSdk.Blockchain

final class WalletConnectPersistConnectedDAppUseCase {
    private let repository: any WalletConnectConnectedDAppRepository

    init(repository: some WalletConnectConnectedDAppRepository) {
        self.repository = repository
    }

    func callAsFunction(
        connectionProposal: WalletConnectDAppConnectionProposal,
        dAppSession: WalletConnectDAppSession,
        dAppBlockchains: [WalletConnectDAppBlockchain],
        userWallet: some UserWalletModel
    ) async throws(WalletConnectDAppPersistenceError) {
        let connectedDApp = WalletConnectConnectedDApp(
            session: dAppSession,
            userWalletID: userWallet.userWalletId.stringValue,
            dAppData: connectionProposal.dAppData,
            verificationStatus: connectionProposal.verificationStatus,
            dAppBlockchains: dAppBlockchains,
            connectionDate: Date.now
        )

        try await repository.save(dApp: connectedDApp)
    }
}
