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
        selectedUserWallet: some UserWalletModel
    ) async throws(WalletConnectDAppPersistenceError) {
        let connectedDApp = WalletConnectConnectedDApp.v1(
            WalletConnectConnectedDAppV1(
                session: dAppSession,
                userWalletID: selectedUserWallet.userWalletId.stringValue,
                dAppData: connectionProposal.dAppData,
                verificationStatus: connectionProposal.verificationStatus,
                dAppBlockchains: dAppBlockchains,
                connectionDate: Date.now
            )
        )

        try await repository.save(dApp: connectedDApp)
    }

    func callAsFunction(
        connectionProposal: WalletConnectDAppConnectionProposal,
        dAppSession: WalletConnectDAppSession,
        dAppBlockchains: [WalletConnectDAppBlockchain],
        selectedUserWallet: some UserWalletModel,
        selectedAccount: any CryptoAccountModel
    ) async throws(WalletConnectDAppPersistenceError) {
        let wrapped = WalletConnectConnectedDAppV1(
            session: dAppSession,
            userWalletID: selectedUserWallet.userWalletId.stringValue,
            dAppData: connectionProposal.dAppData,
            verificationStatus: connectionProposal.verificationStatus,
            dAppBlockchains: dAppBlockchains,
            connectionDate: Date.now
        )

        let connectedDApp = WalletConnectConnectedDApp.v2(
            WalletConnectConnectedDAppV2(
                accountId: selectedAccount.id.walletConnectIdentifierString,
                wrapped: wrapped
            )
        )

        try await repository.save(dApp: connectedDApp)
    }
}
