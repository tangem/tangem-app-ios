//
//  BaseExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct BaseExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL = URL(string: "https://www.alchemy.com/faucets/base-sepolia")
    private let baseExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet ? "https://sepolia.basescan.org" : "https://basescan.org"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}

// MARK: - NFTExternalLinksProvider

extension BaseExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/nft/\(tokenAddress)/\(tokenID)")
    }
}
