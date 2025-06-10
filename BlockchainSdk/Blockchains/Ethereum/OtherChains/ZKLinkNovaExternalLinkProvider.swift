//
//  ZKLinkNovaExternalLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct ZKLinkNovaExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://www.alchemy.com/faucets/ethereum-sepolia")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://sepolia.explorer.zklink.io"
            : "https://explorer.zklink.io"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
