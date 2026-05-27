//
//  KaspaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl: String
    private let baseTokenExplorerUrl: String

    init(isTestnet: Bool) {
        baseExplorerUrl = isTestnet
            ? "https://explorer-tn10.kaspa.org"
            : "https://explorer.kaspa.org"
        baseTokenExplorerUrl = "https://kaspa.stream"
    }

    var testnetFaucetURL: URL? {
        URL(string: "https://faucet-testnet.kaspanet.io")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/transactions/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if contractAddress != nil {
            return URL(string: "\(baseTokenExplorerUrl)/addresses/\(address)")
        }

        return URL(string: "\(baseExplorerUrl)/addresses/\(address)")
    }

    func tokenUrl(transaction hash: String) -> URL? {
        return URL(string: "\(baseTokenExplorerUrl)/transactions/\(hash)")
    }
}
