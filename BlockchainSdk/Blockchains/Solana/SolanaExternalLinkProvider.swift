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
        var urlString = baseUrl + "account/" + address + cluster
        if let contractAddress {
            urlString += "?&token_address=" + contractAddress + "#transfers"
        }
        return URL(string: urlString)
    }
}
