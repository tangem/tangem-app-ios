//
//  RobinhoodExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RobinhoodExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = nil
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet
            ? "https://explorer.testnet.chain.robinhood.com"
            : "https://robinhoodchain.blockscout.com"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
