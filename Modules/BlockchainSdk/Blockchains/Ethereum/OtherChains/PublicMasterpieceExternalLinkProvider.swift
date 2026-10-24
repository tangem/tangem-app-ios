//
//  PublicMasterpieceExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct PublicMasterpieceExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private let baseExplorerUrl = "https://pmtscan.com"

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
