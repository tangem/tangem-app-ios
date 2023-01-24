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

    /// Validates that all blockchains are supported by BlockchainSdk. Currently (24 Jan 2023) we support only EVM blockchains
    /// All other blockchains such as Solana, Tron, Polkadot using different methods, not `eth_sign`, `eth_sendTransaction` etc.
    /// - Returns:
    /// `Bool` that indicates that all blockchains in session proposal is supported
    func allChainsSupported(in namespaces: [String: ProposalNamespace]) -> Bool {
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

    /// Attempts to create `BlockchainNetwork` for each session namespace. This can be used for displaying Blockchain name for user
    /// in an alert with new session connection request
    /// - Returns:
    /// Array of strings with the blockchain names
    func getBlockchainNamesFromNamespaces(_ namespaces: [String: SessionNamespace]) -> [String] {
        let blockchainNetworks = createBlockchains(from: namespaces)

        return blockchainNetworks.map { $0.blockchain.displayName }
    }

    /// If not all blockchains in session proposal request are supported this method will extract all of the not supported blockchain names and capitalize first letter
    /// Capitalization is needed because all blockchain (`chainis` in `WalletConnectSwiftV2` terminology)  in proposal stored as lowercased, e.g. `solana`, `polkadot`
    /// - Returns:
    /// Array of Strings with unsupported blockchain names
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

    /// Wallet must convert all `ProposalNamespace` into `SessionNamespace` with corresponding `Account`s and send session approve to `SignApi`
    /// - Note:
    /// We can use multiple `Account`s for single blockchain. E.g. if user attempting to connect to ETH blockchain if we can create
    /// multiple addresses (using derivation), then we can create `Account`s and they will be displayed in dApp UI. At least in demo dApp it works)
    /// - Returns:
    /// Dictionary with `chains` (`WalletConnectSwiftV2` terminology) as keys and session settings as values.
    /// - Throws:Error with list of unsupported blockchain names or a list of not added to user token list blockchain names
    func createSessionNamespaces(from namespaces: [String: ProposalNamespace], for wallets: [Wallet]) throws -> [String: SessionNamespace] {
        var sessionNamespaces: [String: SessionNamespace] = [:]
        var missingBlockchains: [String] = []
        var unsupportedEVMBlockchains: [String] = []
        for (namespace, proposalNamespace) in namespaces {
            let accounts: [Account] = proposalNamespace.chains.compactMap { wcBlockchain in
                guard let blockchain = createBlockchain(for: wcBlockchain) else {
                    unsupportedEVMBlockchains.append(wcBlockchain.reference)
                    return nil
                }

                guard let wallet = wallets.first(where: { $0.blockchain == blockchain }) else {
                    missingBlockchains.append(blockchain.displayName)
                    return nil
                }

                return Account(wcBlockchain.absoluteString + ":\(wallet.address)")
            }

            let sessionNamespace = SessionNamespace(
                accounts: Set(accounts),
                methods: proposalNamespace.methods,
                events: proposalNamespace.events,
                extensions: nil
            )
            sessionNamespaces[namespace] = sessionNamespace
        }

        guard unsupportedEVMBlockchains.isEmpty else {
            throw WalletConnectV2Error.unsupportedBlockchains(unsupportedEVMBlockchains)
        }

        guard missingBlockchains.isEmpty else {
            throw WalletConnectV2Error.missingBlockchains(missingBlockchains)
        }

        return sessionNamespaces
    }

    /// Method for creating internal session structure for storing on disk. Used for finding information about wallet using session topic.
    /// Also used in UI to display list of connected WC sessions for selected Wallet
    /// - Returns: `WalletConnectSavedSession` with info about wallet, dApp and session
    func createSavedSession(for session: Session, with userWalletId: String) -> WalletConnectSavedSession {
        let targetBlockchains = createBlockchains(from: session.namespaces)

        let dApp = session.peer
        let dAppInfo = WalletConnectSavedSession.DAppInfo(
            name: dApp.name,
            description: dApp.description,
            url: dApp.url,
            iconLinks: dApp.icons
        )
        let sessionInfo = WalletConnectSavedSession.SessionInfo(
            connectedBlockchains: targetBlockchains,
            dAppInfo: dAppInfo
        )

        return WalletConnectSavedSession(
            userWalletId: userWalletId,
            topic: session.topic,
            sessionInfo: sessionInfo
        )
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
