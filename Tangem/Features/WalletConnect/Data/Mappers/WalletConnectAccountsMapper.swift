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
    static func mapToDomain(_ reownAccount: ReownWalletKit.Account) -> WalletConnectDAppConnectionRequest.Account {
        WalletConnectDAppConnectionRequest.Account(
            namespace: reownAccount.namespace,
            reference: reownAccount.reference,
            address: reownAccount.address
        )
    }

    static func mapFromDomain(_ domainAccount: WalletConnectDAppConnectionRequest.Account) -> ReownWalletKit.Account? {
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
        guard let reownBlockchain = WalletConnectBlockchainMapper.mapFromDomain(blockchain, preferredCAIPReference: preferredCAIPReference) else {
            return []
        }

        let wallets = userWalletModel.wcWalletModelProvider.getModels(with: blockchain.networkId)

        guard wallets.isNotEmpty else {
            return []
        }

        return wallets.compactMap { wallet in
            ReownWalletKit.Account(chainIdentifier: reownBlockchain.absoluteString, address: wallet.defaultAddressString)
        }
    }
}
