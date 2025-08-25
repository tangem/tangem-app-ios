//
//  SeiExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SeiExternalLinkProvider {
    private let isTestnet: Bool
    private let chainParam: String
    private let baseURL: String = "https://seitrace.com"

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        chainParam = isTestnet ? "atlantic-2" : "pacific-1"
    }
}

extension SeiExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        URL(string: "https://atlantic-2.app.sei.io/faucet")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseURL)/address/\(address)?chain=\(chainParam)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseURL)/tx/\(hash)?chain=\(chainParam)")
    }
}
