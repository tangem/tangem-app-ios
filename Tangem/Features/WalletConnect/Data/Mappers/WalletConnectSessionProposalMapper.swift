//
//  WalletConnectSessionProposalMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct ReownWalletKit.ProposalNamespace
import struct ReownWalletKit.Session
import struct ReownWalletKit.SessionNamespace
import enum BlockchainSdk.Blockchain

enum WalletConnectSessionProposalMapper {
    static func mapToDomainNamespaces(
        from reownNamespaces: [String: ReownWalletKit.ProposalNamespace]
    ) -> [String: WalletConnectSessionProposal.Namespace] {
        reownNamespaces
            .mapValues { reownProposalNamespace in
                // [REDACTED_USERNAME], Set is used to remove potential duplicates that may happen with solana.
                // DApp may have 2 different ReownWalletKit.Blockchain objects, both representing BlockchainSdk.Blockchain.solana.
                let uniqueBlockchains: Set<BlockchainSdk.Blockchain>?

                if let blockchains = reownProposalNamespace.chains?.compactMap(WalletConnectBlockchainMapper.mapToDomain) {
                    uniqueBlockchains = Set(blockchains)
                } else {
                    uniqueBlockchains = nil
                }

                return WalletConnectSessionProposal.Namespace(
                    blockchains: uniqueBlockchains,
                    methods: reownProposalNamespace.methods,
                    events: reownProposalNamespace.events
                )
            }
    }

    static func mapToOptionalDomainNamespaces(
        from reownNamespaces: [String: ReownWalletKit.ProposalNamespace]?
    ) -> [String: WalletConnectSessionProposal.Namespace]? {
        guard let reownNamespaces else { return nil }
        return Self.mapToDomainNamespaces(from: reownNamespaces)
    }

    static func mapUnsupportedBlockchainNames(from proposal: ReownWalletKit.Session.Proposal) -> Set<String> {
        let unsupportedBlockchainNames: [String] = proposal.requiredNamespaces.reduce([]) { partialResult, reownSessionNamespace in
            guard let reownBlockchains = reownSessionNamespace.value.chains else { return partialResult }

            let unsupportedBlockchainNames = reownBlockchains.compactMap { reownBlockchain in
                let domainBlockchain = WalletConnectBlockchainMapper.mapToDomain(reownBlockchain)

                switch WCUtils.WCSupportedNamespaces(rawValue: reownSessionNamespace.key.lowercased()) {
                case .some where domainBlockchain == nil:
                    return reownBlockchain.absoluteString

                case .some where domainBlockchain != nil:
                    return nil

                default:
                    return domainBlockchain?.displayName ?? reownSessionNamespace.key.capitalizingFirstLetter()
                }
            }

            return partialResult + unsupportedBlockchainNames
        }

        return Set(unsupportedBlockchainNames)
    }
}
