//
//  EthereumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        // The SDK testnet is Sepolia (chain id 11155111); Goerli was shut down in 2024.
        baseURL = isTestnet ? "https://sepolia.etherscan.io/" : "https://etherscan.io/"
        self.isTestnet = isTestnet
    }
}

extension EthereumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://www.alchemy.com/faucets/ethereum-sepolia")
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

extension EthereumExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
