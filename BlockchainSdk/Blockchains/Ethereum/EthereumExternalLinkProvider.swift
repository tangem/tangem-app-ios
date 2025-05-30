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
        baseURL = isTestnet ? "https://goerli.etherscan.io/" : "https://etherscan.io/"
        self.isTestnet = isTestnet
    }
}

extension EthereumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://goerlifaucet.com")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://goerli.etherscan.io/tx/\(hash)")
        }

        return URL(string: "https://etherscan.io/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if let contractAddress {
            let url = baseURL + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseURL + "address/\(address)"
        return URL(string: url)
    }

    func nftURL(tokenAddress: String, tokenID: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
