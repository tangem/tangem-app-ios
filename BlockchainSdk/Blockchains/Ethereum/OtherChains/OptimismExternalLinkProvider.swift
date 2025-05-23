//
//  OptimismExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OptimismExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        baseURL = isTestnet ? "https://goerli-optimism.etherscan.io/" : "https://optimistic.etherscan.io/"
    }
}

extension OptimismExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        // Another one https://faucet.paradigm.xyz
        return URL(string: "https://optimismfaucet.xyz")!
    }

    func url(transaction hash: String) -> URL? {
        URL(string: baseURL + "tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if let contractAddress {
            let url = baseURL + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseURL + "address/\(address)"
        return URL(string: url)
    }
}

// MARK: - NFTExternalLinksProvider

extension OptimismExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
