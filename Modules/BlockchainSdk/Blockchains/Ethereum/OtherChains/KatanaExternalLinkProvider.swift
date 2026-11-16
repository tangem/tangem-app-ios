//
//  KatanaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct KatanaExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = nil

    private let isTestnet: Bool

    private var explorerURL: String {
        if isTestnet {
            "https://bokuto.katanascan.com"
        } else {
            "https://katanascan.com"
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
