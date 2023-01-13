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
    func isAllChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
        for (namespace, _) in namespaces {
            if namespace != "eip155" {
                return false
            }
        }

        return true
    }

    func extractUnsupportedBlockchains(from namespaces: [String: ProposalNamespace]) -> [BlockchainSdk.Blockchain] {
        var blockchains = [BlockchainSdk.Blockchain]()
        for (namespace, proposal) in namespaces {
            if namespace != "eip155", let chain = proposal.chains.first,
               let blockchain = createBlockchain(for: chain) {
                blockchains.append(blockchain)
            }
        }

        return blockchains
    }

    func createSessionNamespaces(from keyedNamespaces: [String: ProposalNamespace], for wallets: [Wallet]) -> [String: SessionNamespace] {
        var sessionNamespaces: [String: SessionNamespace] = [:]
        for (namespace, proposalNamespace) in keyedNamespaces {
            let accounts: [Account] = proposalNamespace.chains.compactMap { wcBlockchain in
                guard
                    let blockchain = createBlockchain(for: wcBlockchain),
                    let wallet = wallets.first(where: { $0.blockchain == blockchain })
                else {
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
        case "eip155":
            return BlockchainSdk.Blockchain.supportedBlockchains.first(where: { $0.chainId == Int(wcBlockchain.reference) })
        default:
            return BlockchainSdk.Blockchain(from: wcBlockchain.namespace)
        }
    }
}
