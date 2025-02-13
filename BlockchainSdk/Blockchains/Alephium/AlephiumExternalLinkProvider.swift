//
//  AlephiumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl = "https://explorer.alephium.org"

    var testnetFaucetURL: URL? {
        URL(string: "https://faucet.testnet.alephium.org/send/")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/addresses/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/transactions/\(hash)")
    }
}
