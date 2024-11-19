//
//  CanxiumExternalLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

struct CanxiumExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private var baseExplorerUrl: String {
        "https://scan.canxium.org"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
