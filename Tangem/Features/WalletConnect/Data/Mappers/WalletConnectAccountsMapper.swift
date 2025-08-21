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
        walletConnectWalletModelProvider: some WalletConnectWalletModelProvider,
        preferredCAIPReference: String?
    ) -> [ReownWalletKit.Account] {
        guard let reownBlockchain = WalletConnectBlockchainMapper.mapFromDomain(blockchain, preferredCAIPReference: preferredCAIPReference) else {
            return []
        }

        let wallets = walletConnectWalletModelProvider.getModels(with: blockchain.networkId)

        guard wallets.isNotEmpty else {
            return []
        }

        return wallets.compactMap { wallet in
            ReownWalletKit.Account(chainIdentifier: reownBlockchain.absoluteString, address: wallet.defaultAddressString)
        }
    }
}
