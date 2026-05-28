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
        selectedUserWallet: some UserWalletModel,
        selectedAccount: any CryptoAccountModel
    ) async throws(WalletConnectDAppPersistenceError) {
        let connectedDApp = WalletConnectConnectedDApp(
            accountId: selectedAccount.id.walletConnectIdentifierString,
            session: dAppSession,
            userWalletID: selectedUserWallet.userWalletId.stringValue,
            dAppData: connectionProposal.dAppData,
            verificationStatus: connectionProposal.verificationStatus,
            dAppBlockchains: dAppBlockchains,
            connectionDate: Date.now
        )

        try await repository.save(dApp: connectedDApp)
    }
}
