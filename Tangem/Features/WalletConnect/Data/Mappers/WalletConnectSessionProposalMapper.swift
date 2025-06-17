//
//  WalletConnectSessionProposalMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit
import enum BlockchainSdk.Blockchain

enum WalletConnectSessionProposalMapper {
    static func mapRequiredBlockchains(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> Set<BlockchainSdk.Blockchain> {
        mapDomainBlockchains(from: reownSessionProposal.requiredNamespaces)
    }

    static func mapOptionalBlockchains(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> Set<BlockchainSdk.Blockchain> {
        guard let optionalNamespaces = reownSessionProposal.optionalNamespaces else {
            return []
        }

        return Self.mapDomainBlockchains(from: optionalNamespaces)
    }

    static func mapUnsupportedRequiredBlockchainNames(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> Set<String> {
        let unsupportedBlockchainNames: [String] = reownSessionProposal.requiredNamespaces.reduce([]) { partialResult, reownSessionNamespace in
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

    static func mapAllMethods(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> [String] {
        let requiredMethods = reownSessionProposal.requiredNamespaces.values.reduce(into: Set<String>()) { result, namespace in
            result.formUnion(namespace.methods)
        }

        let optionalMethods = reownSessionProposal.optionalNamespaces?.values.reduce(into: Set<String>()) { result, namespace in
            result.formUnion(namespace.methods)
        } ?? []

        return Array(requiredMethods.union(optionalMethods))
    }

    static func mapAllEvents(from reownSessionProposal: ReownWalletKit.Session.Proposal) -> [String] {
        let requiredEvents = reownSessionProposal.requiredNamespaces.values.reduce(into: Set<String>()) { result, namespace in
            result.formUnion(namespace.events)
        }

        let optionalEvents = reownSessionProposal.optionalNamespaces?.values.reduce(into: Set<String>()) { result, namespace in
            result.formUnion(namespace.events)
        } ?? []

        return Array(requiredEvents.union(optionalEvents))
    }

    static func mapRejectionReason(fromDomain reason: WalletConnectDAppSessionProposalRejectionReason) -> ReownWalletKit.RejectionReason {
        switch reason {
        case .userInitiated:
            .userRejected

        case .unsupportedDAppDomain:
            // [REDACTED_USERNAME], ReownWalletKit does not provide a suitable rejection reason for unsupported domain case.
            // RejectionReason.userRejected is used as a fallback.
            .userRejected

        case .unsupportedBlockchains:
            .unsupportedChains
        }
    }

    // MARK: - Private methods

    private static func mapDomainBlockchains(from reownNamespaces: [String: ReownWalletKit.ProposalNamespace]) -> Set<BlockchainSdk.Blockchain> {
        reownNamespaces
            .values
            .reduce(into: Set<BlockchainSdk.Blockchain>()) { result, reownProposalNamespace in
                let blockchains = reownProposalNamespace.chains?.compactMap(WalletConnectBlockchainMapper.mapToDomain) ?? []

                // [REDACTED_USERNAME], Set is used to remove potential duplicates that may happen with solana.
                // DApp may have 2 different ReownWalletKit.Blockchain objects, both representing BlockchainSdk.Blockchain.solana.
                result.formUnion(blockchains)
            }
    }
}
