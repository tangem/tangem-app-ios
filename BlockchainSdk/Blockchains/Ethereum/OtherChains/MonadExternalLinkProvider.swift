//
//  MonadExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MonadExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL?
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet ? "https://testnet.monadscan.com" : "https://monadscan.com"
        testnetFaucetURL = isTestnet ? URL(string: "https://faucet.monad.xyz") : nil
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
