//
//  QuickNodeAPIResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct QuickNodeAPIResolver {
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(for blockchain: Blockchain) -> NodeInfo? {
        guard let credentials = resolveCredentials(for: blockchain) else {
            return nil
        }

        if case .sui = blockchain {
            return resolveGRPC(credentials: credentials)
        }

        guard var url = URL(string: "https://\(credentials.subdomain)/\(credentials.apiKey)") else {
            return nil
        }

        switch blockchain {
        case .hedera:
            url.append(path: "api/v1")
        default:
            break
        }

        return NodeInfo(url: url)
    }

    private func resolveGRPC(credentials: BlockchainSdkKeysConfig.QuickNodeCredentials) -> NodeInfo? {
        guard
            !credentials.subdomain.isEmpty,
            !credentials.apiKey.isEmpty,
            let url = URL(string: "https://\(credentials.subdomain):9000")
        else {
            return nil
        }

        return NodeInfo(url: url, keyInfo: .init(headerName: Constants.quickNodeGRPCTokenHeaderName, headerValue: credentials.apiKey))
    }

    private func resolveCredentials(for blockchain: Blockchain) -> BlockchainSdkKeysConfig.QuickNodeCredentials? {
        switch blockchain {
        case .bsc:
            return keysConfig.quickNodeBscCredentials
        case .xrp:
            return keysConfig.quickNodeXrpCredentials
        case .hedera:
            return keysConfig.quickNodeHederaCredentials
        case .solana:
            return keysConfig.quickNodeSolanaCredentials
        case .plasma:
            return keysConfig.quickNodePlasmaCredentials
        case .monad:
            return keysConfig.quickNodeMonadCredentials
        case .robinhood:
            return keysConfig.quickNodeRobinhoodCredentials
        case .arc:
            return keysConfig.quickNodeArcCredentials
        case .sui:
            return keysConfig.quickNodeSuiCredentials
        default:
            return nil
        }
    }
}
