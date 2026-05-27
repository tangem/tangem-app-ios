//
//  PolygonExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PolygonExternalLinkProvider {
    private let isTestnet: Bool
    private let baseURL: String

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        baseURL = isTestnet ? "https://mumbai.polygonscan.com/" : "https://polygonscan.com/"
    }
}

extension PolygonExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.matic.network")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://mumbai.polygonscan.com/tx/\(hash)")
        }

        return URL(string: "https://polygonscan.com/tx/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if let contractAddress {
            let url = baseURL + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)
        }

        let url = baseURL + "address/\(address)"
        return URL(string: url)
    }
}

// MARK: - NFTExternalLinksProvider

extension PolygonExternalLinkProvider: NFTExternalLinksProvider {
    func url(tokenAddress: String, tokenID: String, contractType: String) -> URL? {
        URL(string: baseURL + "nft/\(tokenAddress)/\(tokenID)")
    }
}
