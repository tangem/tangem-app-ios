//
//  GonkaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GonkaExternalLinkProvider {}

extension GonkaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        nil
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "https://gonka.gg/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "https://gonka.gg/transactions/\(hash)")
    }
}
