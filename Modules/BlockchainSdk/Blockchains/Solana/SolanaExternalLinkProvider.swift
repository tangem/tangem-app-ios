//
//  SolanaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaExternalLinkProvider {
    private let isTestnet: Bool
    private let baseUrl = "https://solscan.io/"
    private let cluster: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        cluster = isTestnet ? "?cluster=testnet" : ""
    }
}

extension SolanaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://solfaucet.com")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: baseUrl + "tx/" + hash + cluster)
    }

    func url(address: String, contractAddress: String?) -> URL? {
        guard let contractAddress else {
            return URL(string: baseUrl + "account/" + address + cluster)
        }

        // `cluster` already starts the query on testnet, so the token filter has to be appended with `&`, not `?`.
        var components = URLComponents(string: baseUrl + "account/" + address)
        var queryItems: [URLQueryItem] = []
        if isTestnet {
            queryItems.append(URLQueryItem(name: "cluster", value: "testnet"))
        }
        queryItems.append(URLQueryItem(name: "token_address", value: contractAddress))
        components?.queryItems = queryItems
        components?.fragment = "transfers"
        return components?.url
    }
}

// MARK: - NFTExternalLinksProvider

extension SolanaExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseUrl + "token/\(tokenAddress)" + cluster)
    }
}
