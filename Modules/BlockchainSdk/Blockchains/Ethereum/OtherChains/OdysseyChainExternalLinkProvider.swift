//
//  OdysseyChainExternalLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct OdysseyChainExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String

    let testnetFaucetURL = URL(string: "https://faucet.dioneprotocol.com")

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://testnet.odysseyscan.com"
            : "https://odysseyscan.com"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
