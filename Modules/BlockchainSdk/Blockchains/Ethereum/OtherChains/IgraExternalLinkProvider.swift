//
//  IgraExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct IgraExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = nil
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet
            ? "https://explorer.galleon-testnet.igralabs.com"
            : "https://explorer.igralabs.com"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
