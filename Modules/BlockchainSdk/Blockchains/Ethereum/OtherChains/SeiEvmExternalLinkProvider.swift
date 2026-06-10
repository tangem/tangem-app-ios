//
//  SeiEvmExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SeiEvmExternalLinkProvider: ExternalLinkProvider {
    private let isTestnet: Bool

    private var baseExplorerURL: String {
        isTestnet ? "https://testnet.seiscan.io" : "https://seiscan.io"
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    var testnetFaucetURL: URL? {
        isTestnet ? URL(string: "https://docs.sei.io/learn/faucet") : nil
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerURL)/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerURL)/address/\(address)")
    }
}
