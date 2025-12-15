//
//  ArbitrumNovaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ArbitrumNovaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private var baseExplorerUrl: String {
        "https://nova.arbiscan.io"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
