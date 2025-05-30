//
//  ChilizExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ChilizExternalLinkProvider {
    private let baseExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://testnet.chiliscan.com"
            : "https://chiliscan.com"
    }
}

extension ChilizExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://tatum.io/faucets/chiliz/")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}

// MARK: - NFTExternalLinksProvider

extension ChilizExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/nft/\(tokenAddress)/\(tokenID)")
    }
}
