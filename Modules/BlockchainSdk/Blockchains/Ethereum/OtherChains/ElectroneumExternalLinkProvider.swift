//
//  ElectroneumExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ElectroneumExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = nil
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet
            ? "https://testnet-blockexplorer.electroneum.com"
            : "https://blockexplorer.electroneum.com"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
