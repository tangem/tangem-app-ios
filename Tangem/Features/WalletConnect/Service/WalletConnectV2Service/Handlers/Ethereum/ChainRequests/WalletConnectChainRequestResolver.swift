//
//  WalletConnectChainRequestResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit
import enum BlockchainSdk.Blockchain
import TangemFoundation

enum WalletConnectChainRequestResolver {
    static func resolve(
        method: WalletConnectMethod?,
        params: AnyCodable,
        sessionBlockchains: [BlockchainSdk.Blockchain]
    ) -> Resolution? {
        switch method {
        case .switchChain:
            guard let chainId = singleChainId(from: params, as: ChainEntry.self, \.chainId) else {
                return .invalidParams
            }

            guard let blockchain = blockchain(chainId: chainId), isConnected(blockchain, to: sessionBlockchains) else {
                return .unrecognizedChain
            }

            return .switched(blockchain)
        case .addChain:
            guard let chainId = singleChainId(from: params, as: WalletConnectAddEthereumChainMessageHandler.RequestParameterEntry.self, \.chainId) else {
                return .invalidParams
            }

            guard let blockchain = blockchain(chainId: chainId), isConnected(blockchain, to: sessionBlockchains) else {
                return .needsUserApproval
            }

            return .alreadyAdded(blockchain)
        default:
            return nil
        }
    }

    private static func singleChainId<Entry: Codable>(from params: AnyCodable, as type: Entry.Type, _ chainId: KeyPath<Entry, String>) -> Int? {
        guard let entries = try? params.get([Entry].self), entries.count == 1, let entry = entries.first else {
            return nil
        }

        return entry[keyPath: chainId].hexToInt()
    }

    private static func blockchain(chainId: Int) -> BlockchainSdk.Blockchain? {
        guard
            let reownBlockchain = ReownWalletKit.Blockchain(
                namespace: WalletConnectSupportedNamespace.eip155.rawValue,
                reference: String(chainId)
            )
        else {
            return nil
        }

        return WalletConnectBlockchainMapper.mapToDomain(reownBlockchain)
    }

    private static func isConnected(_ blockchain: BlockchainSdk.Blockchain, to sessionBlockchains: [BlockchainSdk.Blockchain]) -> Bool {
        sessionBlockchains.contains { $0.networkId == blockchain.networkId }
    }
}

// MARK: - Resolution

extension WalletConnectChainRequestResolver {
    enum Resolution: Equatable {
        case switched(BlockchainSdk.Blockchain)
        case alreadyAdded(BlockchainSdk.Blockchain)
        case unrecognizedChain
        case invalidParams
        case needsUserApproval
    }
}

// MARK: - ChainEntry

private extension WalletConnectChainRequestResolver {
    struct ChainEntry: Codable {
        let chainId: String
    }
}
