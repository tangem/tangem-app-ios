//
//  WalletConnectAccountsMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.Account
import enum BlockchainSdk.Blockchain
import TangemFoundation

enum WalletConnectAccountsMapper {
    static func mapToDomain(_ reownAccount: ReownWalletKit.Account) -> WalletConnectAccount {
        WalletConnectAccount(
            namespace: reownAccount.namespace,
            reference: reownAccount.reference,
            address: reownAccount.address
        )
    }

    static func mapFromDomain(_ domainAccount: WalletConnectAccount) -> ReownWalletKit.Account? {
        ReownWalletKit.Account(
            chainIdentifier: "\(domainAccount.namespace):\(domainAccount.reference)",
            address: domainAccount.address
        )
    }

    static func map(
        from blockchain: BlockchainSdk.Blockchain,
        userWalletModel: some UserWalletModel,
        preferredCAIPReference: String?
    ) -> [ReownWalletKit.Account] {
        map(
            from: blockchain,
            walletConnectWalletModelProvider: userWalletModel.wcWalletModelProvider,
            preferredCAIPReference: preferredCAIPReference
        )
    }

    static func map(
        from blockchain: BlockchainSdk.Blockchain,
        wcAccountsWalletModelProvider: some WalletConnectAccountsWalletModelProvider,
        accountId: String,
        preferredCAIPReference: String?
    ) -> [ReownWalletKit.Account] {
        map(
            from: blockchain,
            wcAccountsWalletModelProvider: wcAccountsWalletModelProvider,
            preferredCAIPReference: preferredCAIPReference,
            accountId: accountId
        )
    }

    static func map(
        from blockchain: BlockchainSdk.Blockchain,
        walletConnectWalletModelProvider: some WalletConnectWalletModelProvider,
        preferredCAIPReference: String?
    ) -> [ReownWalletKit.Account] {
        guard let reownBlockchain = WalletConnectBlockchainMapper.mapFromDomain(blockchain, preferredCAIPReference: preferredCAIPReference) else {
            return []
        }

        let wallets = walletConnectWalletModelProvider.getModels(with: blockchain.networkId)

        // In legacy wallet flow we should expose only one address per network.
        // Returning all models may connect multiple addresses for the same wallet.
        guard let wallet = walletConnectWalletModelProvider.getModel(with: blockchain.networkId) ?? wallets.first else {
            return []
        }

        guard let account = ReownWalletKit.Account(
            chainIdentifier: reownBlockchain.absoluteString,
            address: wallet.walletConnectAddress
        ) else {
            return []
        }

        return [account]
    }

    static func map(
        from blockchain: BlockchainSdk.Blockchain,
        wcAccountsWalletModelProvider: some WalletConnectAccountsWalletModelProvider,
        preferredCAIPReference: String?,
        accountId: String
    ) -> [ReownWalletKit.Account] {
        guard let reownBlockchain = WalletConnectBlockchainMapper.mapFromDomain(blockchain, preferredCAIPReference: preferredCAIPReference) else {
            return []
        }

        let wallets = wcAccountsWalletModelProvider.getModels(
            with: blockchain.networkId,
            accountId: accountId
        )

        guard wallets.isNotEmpty else {
            return []
        }

        return wallets.compactMap { wallet in
            ReownWalletKit.Account(chainIdentifier: reownBlockchain.absoluteString, address: wallet.walletConnectAddress)
        }
    }
}
