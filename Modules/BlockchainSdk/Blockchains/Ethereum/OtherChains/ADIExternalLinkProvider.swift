//
//  ADIExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ADIExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://sepolia.etherscan.io/token/0x2a98b46fe31ba8be05ef1ce3d36e1f80db04190d?a=0xf5B0Ae14b62454782F79559aD28394213401d59B#readProxyContract")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://explorer.ab.testnet.adifoundation.ai"
            : "https://explorer.adifoundation.ai"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
