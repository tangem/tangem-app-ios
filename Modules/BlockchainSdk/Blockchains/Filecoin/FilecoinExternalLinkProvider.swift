//
//  FilecoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl = "https://filfox.info"

    var testnetFaucetURL: URL? {
        URL(string: "https://faucet.calibnet.chainsafe-fil.io")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/message/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
}
