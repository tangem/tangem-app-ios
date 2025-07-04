//
//  CloreExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CloreExternalLinkProvider {}

extension CloreExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private var explorerBaseURL: String {
        return "https://clore.cryptoscope.io/"
    }

    func url(transaction hash: String) -> URL? {
        let queryParam = "?txid="
        return URL(string: explorerBaseURL + "tx/\(queryParam)\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        let queryParam = "?address="
        return URL(string: explorerBaseURL + "address/\(queryParam)\(address)")
    }
}
