//
//  NowNodesBlockBookConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// https://nownodes.io/nodes
struct NowNodesBlockBookConfig: BlockBookConfig {
    let apiKeyHeaderName: String?
    let apiKeyHeaderValue: String?

    init(apiKeyHeaderName: String?, apiKeyHeaderValue: String?) {
        self.apiKeyHeaderName = apiKeyHeaderName
        self.apiKeyHeaderValue = apiKeyHeaderValue
    }
}

extension NowNodesBlockBookConfig {
    var host: String {
        return "nownodes.io"
    }

    func node(for blockchain: Blockchain) -> BlockBookNode {
        let prefix = blockchain.currencySymbol.lowercased()

        switch blockchain {
        case .bitcoin,
             .dash,
             .dogecoin,
             .litecoin,
             .bitcoinCash:
            let testnetSuffix = blockchain.isTestnet ? "-testnet" : ""
            return BlockBookNode(
                rpcNode: URL(string: "https://\(prefix).\(host)")!,
                restNode: URL(string: "https://\(prefix)book\(testnetSuffix).\(host)")!
            )
        case .ethereum,
             .ethereumPoW,
             .ethereumClassic,
             .avalanche,
             .ravencoin,
             .tron:
            return BlockBookNode(
                rpcNode: URL(string: "https://\(prefix).\(host)")!,
                restNode: URL(string: "https://\(prefix)-blockbook.\(host)")!
            )
        case .bsc:
            return BlockBookNode(
                rpcNode: URL(string: "https://bsc.\(host)")!,
                restNode: URL(string: "http://bsc-blockbook.\(host)")!
            )
        case .arbitrum:
            // L2 blockchains use `currencySymbol` from their L1s, so we can't just
            // use the `prefix` variable here for L2s like Arbitrum, Optimism, etc
            return BlockBookNode(
                rpcNode: URL(string: "https://arbitrum.\(host)")!,
                restNode: URL(string: "https://arb-blockbook.\(host)")!
            )
        default:
            fatalError("NowNodesBlockBookConfig don't support blockchain: \(blockchain.displayName)")
        }
    }

    func path(for request: BlockBookTarget.Request) -> String {
        switch request {
        case .rpc:
            return ""
        default:
            return "/api/v2"
        }
    }
}
