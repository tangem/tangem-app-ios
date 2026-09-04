//
//  ArcExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ArcExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL?
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet
            ? "https://testnet.arcscan.app"
            : "https://explorer.arc.io"
        testnetFaucetURL = isTestnet ? URL(string: "https://faucet.circle.com") : nil
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
