//
//  PlasmaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct PlasmaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        .init(string: "https://www.gas.zip/faucet/plasma")
    }

    private let isTestnet: Bool

    private var baseExplorerUrl: String {
        if isTestnet {
            "https://testnet.plasmascan.to"
        } else {
            "https://plasmascan.to"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        var urlComponents = URLComponents(string: "\(baseExplorerUrl)/address/\(address)")!

        if let contractAddress {
            urlComponents.path.append("/tokentxns")

            let contractAddressItem = URLQueryItem(name: "tokenaddress", value: contractAddress)
            urlComponents.queryItems = [contractAddressItem]
        }

        return urlComponents.url
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/tx/\(hash)")
    }
}
