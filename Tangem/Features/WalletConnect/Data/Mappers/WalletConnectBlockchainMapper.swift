//
//  WalletConnectBlockchainMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.Blockchain
import enum BlockchainSdk.Blockchain

enum WalletConnectBlockchainMapper {
    static func mapToDomain(_ reownBlockchain: ReownWalletKit.Blockchain) -> BlockchainSdk.Blockchain? {
        guard WCUtils.WCSupportedNamespaces(rawValue: reownBlockchain.namespace.lowercased()) != nil else {
            return nil
        }

        return SupportedBlockchains
            .all
            .first { domainBlockchain in
                domainBlockchain.wcChainID?.contains(reownBlockchain.reference) ?? false
            }
    }

    static func mapFromDomain(_ domainBlockchain: BlockchainSdk.Blockchain) -> ReownWalletKit.Blockchain? {
        mapFromDomain(domainBlockchain, preferredCAIPReference: nil)
    }

    static func mapFromDomain(_ domainBlockchain: BlockchainSdk.Blockchain, preferredCAIPReference: String?) -> ReownWalletKit.Blockchain? {
        if case .solana = domainBlockchain, let solanaReownReferences = domainBlockchain.wcChainID, !solanaReownReferences.isEmpty {
            return ReownWalletKit.Blockchain(
                namespace: WCUtils.WCSupportedNamespaces.solana.rawValue,
                reference: preferredCAIPReference ?? solanaReownReferences[0]
            )
        }

        if domainBlockchain.isEvm, let chainId = domainBlockchain.chainId {
            return ReownWalletKit.Blockchain(
                namespace: WCUtils.WCSupportedNamespaces.eip155.rawValue,
                reference: preferredCAIPReference ?? String(chainId)
            )
        }

        return nil
    }
}
