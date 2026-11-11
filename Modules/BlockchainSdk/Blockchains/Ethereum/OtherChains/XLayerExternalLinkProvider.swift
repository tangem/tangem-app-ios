//
//  XLayerExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct XLayerExternalLinkProvider: ExternalLinkProvider {
    private let isTestnet: Bool

    var testnetFaucetURL: URL? {
        isTestnet ? URL(string: "https://web3.okx.com/xlayer/faucet") : nil
    }

    private var explorerURL: String {
        if isTestnet {
            "https://web3.okx.com/explorer/xlayer-test"
        } else {
            "https://web3.okx.com/explorer/x-layer"
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
