//
//  DisChainExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DisChainExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private let explorerBaseURL = "https://explorer.dischain.xyz"

    func url(transaction hash: String) -> URL? {
        URL(string: "\(explorerBaseURL)/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(explorerBaseURL)/address/\(address)")
    }
}
