//
//  WalletConnectV2Utils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwiftV2
import BlockchainSdk

struct WalletConnectV2Utils {
    private let evmNamespace = "eip155"

    func isAllChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
        for (namespace, proposals) in namespaces {
            if namespace != evmNamespace {
                return false
            }

            let blockchains = proposals.chains.compactMap(createBlockchain(for:))
            if blockchains.count != proposals.chains.count {
                return false
            }
        }

        return true
    }

    func getBlockchainNamesFromNamespaces(_ namespaces: [String: SessionNamespace]) -> [String] {
        let blockchainNetworks = createBlockchains(from: namespaces)

        return blockchainNetworks.map { $0.blockchain.displayName }
    }

    func extractUnsupportedBlockchainNames(from namespaces: [String: ProposalNamespace]) -> [String] {
        var blockchains = [String]()
        for (namespace, proposal) in namespaces {
            if namespace != evmNamespace, let chain = proposal.chains.first {
                let blockchain = createBlockchain(for: chain)?.displayName ?? namespace.capitalizingFirstLetter()
                blockchains.append(blockchain)
            }
        }

        return blockchains
    }

    func createSessionNamespaces(from keyedNamespaces: [String: ProposalNamespace], for wallets: [Wallet]) throws -> [String: SessionNamespace] {
        var sessionNamespaces: [String: SessionNamespace] = [:]
        var missingChains = [String]()
        var unsupportedEVMChains = [String]()
        for (namespace, proposalNamespace) in keyedNamespaces {
            let accounts: [Account] = proposalNamespace.chains.compactMap { wcBlockchain in
                guard let blockchain = createBlockchain(for: wcBlockchain) else {
                    unsupportedEVMChains.append(wcBlockchain.reference)
                    return nil
                }

                guard let wallet = wallets.first(where: { $0.blockchain == blockchain }) else {
                    missingChains.append(blockchain.displayName)
                    return nil
                }

                return Account(wcBlockchain.absoluteString + ":\(wallet.address)")
            }

            let filteredAccounts = Set(accounts)
            let sessionNamespace = SessionNamespace(accounts: filteredAccounts,
                                                    methods: proposalNamespace.methods,
                                                    events: proposalNamespace.events,
                                                    extensions: nil)
            sessionNamespaces[namespace] = sessionNamespace
        }

        guard unsupportedEVMChains.isEmpty else {
            throw WalletConnectV2Error.unsupportedBlockchains(unsupportedEVMChains)
        }

        guard missingChains.isEmpty else {
            throw WalletConnectV2Error.missingBlockchains(missingChains)
        }

        return sessionNamespaces
    }

    func createSavedSession(for session: Session, with userWalletId: String) -> WalletConnectSavedSession {
        let targetBlockchains = createBlockchains(from: session.namespaces)

        let dApp = session.peer
        let dAppInfo = WalletConnectSavedSession.DAppInfo(name: dApp.name,
                                                          description: dApp.description,
                                                          url: dApp.url,
                                                          iconsLinks: dApp.icons,
                                                          supportedChains: nil)
        let sessionInfo = WalletConnectSavedSession.SessionInfo(connectedBlockchains: targetBlockchains,
                                                                dAppInfo: dAppInfo)

        return WalletConnectSavedSession(userWalletId: userWalletId,
                                         topic: session.topic,
                                         sessionInfo: sessionInfo)
    }

    private func createBlockchains(from namespaces: [String: SessionNamespace]) -> [BlockchainNetwork] {
        var blockchains = [BlockchainSdk.Blockchain]()
        for (_, sessionNamespace) in namespaces {
            let wcBlockchains = sessionNamespace.accounts.compactMap { $0.blockchain }
            let tangemBlockchains = wcBlockchains.compactMap(createBlockchain(for:))
            blockchains.append(contentsOf: tangemBlockchains)
        }

        return blockchains.map { BlockchainNetwork($0, derivationPath: $0.derivationPath(for: .new)) }
    }

    private func createBlockchain(for wcBlockchain: WalletConnectSwiftV2.Blockchain) -> BlockchainSdk.Blockchain? {
        switch wcBlockchain.namespace {
        case evmNamespace:
            return BlockchainSdk.Blockchain.supportedBlockchains.first(where: { $0.chainId == Int(wcBlockchain.reference) })
        default:
            return BlockchainSdk.Blockchain(from: wcBlockchain.namespace)
        }
    }
}
