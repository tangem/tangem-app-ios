//
//  FantomExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct FantomExternalLinkProvider {
    private let baseUrl: String
    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        baseUrl = isTestnet ? "https://explorer.testnet.fantom.network/" : "https://oklink.com/fantom/"
    }
}

extension FantomExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://faucet.fantom.network")
    }

    func url(transaction hash: String) -> URL? {
        let txPath = isTestnet ? "transactions/" : "tx/"
        return URL(string: baseUrl + txPath + "\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        var urlString = baseUrl + "address/\(address)"
        if let contractAddress {
            urlString += "/token-transfer#token-address=\(contractAddress)"
        }
        return URL(string: urlString)
    }
}
