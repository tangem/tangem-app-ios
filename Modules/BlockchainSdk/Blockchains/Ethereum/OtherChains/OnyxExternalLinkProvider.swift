//
//  OnyxExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OnyxExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = nil

    private let isTestnet: Bool

    private var explorerURL: String {
        if isTestnet {
            "https://testnet.explorer.goliath.net"
        } else {
            "https://explorer.onyx.org"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
